class Cosmos::BlockSyncService < Cosmos::SyncBase
  def sync!
    sync_start_height = @chain.latest_local_height
    target_height = get_status['result']['sync_info']['latest_block_height'].to_i
    target_height -= 1 # only load up to latest canonical block

    if ENV['LIMIT_NEW_BLOCKS']
      target_height = [sync_start_height + ENV['LIMIT_NEW_BLOCKS'].to_i, target_height].min
    end

    if sync_start_height >= target_height
      puts "No new blocks to sync."
    else
      ProgressReport.instance.start "Syncing blocks on #{@chain.slug} (#{sync_start_height} -> #{target_height}) from #{@host}..."

      latest_local = sync_start_height
      while latest_local < target_height
        Cosmos::Block.bulk_insert do |worker|
          batch_start_time = Time.now.utc.to_f

          page_start = latest_local+1
          page_end = [latest_local+BATCH_SIZE, target_height].min
          data = get_blocks( page_start, page_end )
          break if data.has_key?('error')

          heights = data['result']['block_metas'].map { |bm| bm.dig('header', 'height').to_i }.sort
          expected_heights = (page_start..page_end).to_a.sort
          if heights != expected_heights
            puts "\n\nDEBUG PAYLOAD: #{data.to_json}\n\n\n"
            raise Cosmos::SyncBase::CriticalError.new("Block page #{page_start} -> #{page_end} is missing heights -- #{(expected_heights - heights).join(', ')}!")
          end

          blocks_data = data['result']['block_metas']
          # puts "BLOCKS: #{blocks_data.map { |b| b['header']['height'] }.join(',')}"
          blocks_data.reverse_each do |block|
            begin
              height = block['header']['height'].to_i
              next if height <= latest_local
            rescue
              puts "\n\nDEBUG PAYLOAD: #{data.to_json}\n\n\n"
              raise Cosmos::SyncBase::CriticalError.new("Empty block object found in page #{page_start}->#{page_end}")
            end

            begin
              commit = get_commit(height)

              if !commit['result']['canonical']
                target_height = height - 1
                break
              end
            rescue
              puts "\n\nDEBUG PAYLOAD: #{commit.to_json}\n\n\n"
              raise Cosmos::SyncBase::CriticalError.new("Empty or invalid commit object found for block #{height}.")
            end

            obj = Cosmos::Block.assemble(
              @chain, height,
              block, commit, get_validator_set(height)
            )

            if obj[:transactions].try(:any?)
              begin
                txs = obj[:transactions].map { |hash| get_transaction(hash) }
                Cosmos::AccountFinder.new( @chain, txs, :transactions ).run
              rescue
                puts "Failed to run account finder: #{$!.message}"
              end
            end

            worker.add( obj )
            latest_local = height

            ProgressReport.instance.progress sync_start_height, height, target_height
          end

          ProgressReport.instance.benchmark (Time.now.utc.to_f - batch_start_time) / blocks_data.count
        end
      end

      ProgressReport.instance.report
    end

    @chain.update_attributes last_sync_time: Time.now.utc
  end
end
