namespace :sync do
  namespace :cosmos do
    desc 'Sync cosmos blocks'
    task blocks: :environment do
      TaskLock.with_lock!( :cosmos, :sync ) do
        puts "\nStarting sync:cosmos:blocks task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
        Cosmos::Chain.enabled.find_each do |chain|
          Cosmos::BlockSyncService.new(chain).sync! rescue nil
        end
        puts "Completed sync:cosmos:blocks task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}\n\n"
      end
    end

    desc 'Sync cosmos validators (create new, update timestamps, etc)'
    task validators: :environment do
      TaskLock.with_lock!( :cosmos, :sync ) do
        puts "\nStarting sync:cosmos:validators task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
        Cosmos::Chain.enabled.find_each do |chain|
          begin
            vss = Cosmos::ValidatorSyncService.new(chain)
            vss.sync_validator_timestamps!
            vss.sync_validator_metadata! if chain.enabled?
            vss.update_history_height!
          rescue
            nil
          end
        end
        puts "Completed sync:cosmos:validators task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}\n\n"
      end
    end

    desc 'Sync cosmos faucets'
    task faucets: :environment do
      TaskLock.with_lock!( :cosmos, :sync ) do
        puts "\nStarting sync:cosmos:faucets task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
        Cosmos::Chain.enabled.find_each do |chain|
          next unless chain.faucet
          begin
            fss = Cosmos::FaucetSyncService.new(chain)
            fss.sync_token_info!
          rescue
            nil
          end
        end
        puts "Completed sync:cosmos:faucets task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}\n\n"
      end
    end

    desc 'Update cosmos blocks and validators'
    task all: :environment do
      TaskLock.with_lock!( :cosmos, :sync ) do
        puts "\nStarting sync:cosmos:all task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
        Cosmos::Chain.enabled.find_each do |chain|
          begin
            bss = Cosmos::BlockSyncService.new(chain)
            bss.sync!

            vss = Cosmos::ValidatorSyncService.new(chain)
            vss.sync_validator_timestamps!
            vss.sync_validator_metadata!
            vss.update_history_height!

            fss = Cosmos::FaucetSyncService.new(chain)
            fss.sync_token_info!
          rescue
            nil
          end
        end
        puts "Completed sync:cosmos:all task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}\n\n"
      end
    end
  end
end
