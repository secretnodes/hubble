namespace :backfill_transactions do
  %w{ secret enigma cosmos terra iris kava }.each do |network|
    task :"#{network.to_sym}" => :environment do
      $stdout.sync = true
      puts "\nStarting sync:#{network} task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
      network.titleize.constantize::Chain.enabled.find_each do |chain|
        syncer = chain.syncer( 10_000 )
        sync_start_height = 310720
        target_height = syncer.get_head_height
        target_height -= chain.class::SYNC_OFFSET # leave some blocks off (non-canonical, or stay behind on purpose)

        latest_local = sync_start_height

        if sync_start_height >= target_height
          puts "No new blocks to sync."
        else
          chain_syncer = chain.namespace::SyncBase.new( chain, 250 )
          while latest_local < target_height
            page_start = latest_local+1
            page_end = [latest_local+20, target_height].min
            break if page_start > page_end

            data = syncer.get_blocks( page_start, page_end )
            blocks_data = data['result']['block_metas']
            break if blocks_data.nil?
            blocks_data.each do |meta|
              height = meta['header']['height'].to_i
              if meta['num_txs'].to_i > 0
                block_txs = chain_syncer.get_block( height )['result']['block']['data']['txs']
                
                if block_txs.present?
                  begin
                    transactions = block_txs.try(:map) { |data| Digest::SHA256.hexdigest(Base64.decode64(data)) }
                  rescue
                    raise chain.namespace::SyncBase::CriticalError.new("Unable to decode or invalid transaction data for block #{height}.")
                  end
                end

                block = chain.namespace::Block.find_by_height height.to_i
                block.update transactions: transactions
              end
            end
            latest_local = blocks_data.first['header']['height'].to_i
            puts latest_local
          end
        end
      end
    end
  end
end