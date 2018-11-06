class Cosmos::BlockSyncService < Cosmos::SyncBase
  def sync!
    sync_start_height = @chain.latest_local_height

    log = Stats::SyncLog.start( @chain, sync_start_height )

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

          data = get_blocks latest_local+1, latest_local+BATCH_SIZE
          break if data.has_key?('error')

          blocks_data = data['result']['block_metas']
          # puts "BLOCKS: #{blocks_data.map { |b| b['header']['height'] }.join(',')}"
          blocks_data.reverse_each do |block|
            height = block['header']['height'].to_i
            commit = get_commit(height)

            if !commit['result']['canonical']
              target_height = height - 1
              break
            end

            obj = Cosmos::Block.assemble(
              @chain, height,
              block, commit, get_validator_set(height)
            )

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
    log.end( @chain.latest_local_height )
  rescue
    log.error $!
  end
end
