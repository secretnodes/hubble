namespace :sync do
  namespace :cosmos do

    desc 'Run all sync tasks on all chains'
    task all: :environment do
      puts "\nStarting sync:cosmos:all task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
      Cosmos::Chain.enabled.find_each do |chain|
        TaskLock.with_lock!(:sync, chain.id) do
          log = Stats::SyncLog.start( chain )

          begin
            log.set_status 'blocks'
            bss = Cosmos::BlockSyncService.new(chain)
            bss.sync!
          rescue
            log.report_error $!
            log.end && next if $!.is_a?(Cosmos::SyncBase::CriticalError)
            puts "Failed to complete block sync!\n#{$!.message}"
            puts $!.backtrace.join("\n") && puts if ENV['DEBUG']
          end

          begin
            log.set_status 'governance'
            gss = Cosmos::GovSyncService.new(chain)
            gss.sync!
          rescue
            log.report_error $!
            log.end && next if $!.is_a?(Cosmos::SyncBase::CriticalError)
            puts "Failed to complete governance sync!\n#{$!.message}"
            puts $!.backtrace.join("\n") && puts if ENV['DEBUG']
          end

          begin
            log.set_status 'halt-check'
            hcs = Cosmos::HaltedChainService.new(chain)
            hcs.check_for_halted_chain!
          rescue
            log.report_error $!
            log.end && next if $!.is_a?(Cosmos::SyncBase::CriticalError)
            puts "Failed to complete halt check!\n#{$!.message}"
            puts $!.backtrace.join("\n") && puts if ENV['DEBUG']
          end

          begin
            log.set_status 'validators'
            vss = Cosmos::ValidatorSyncService.new(chain)
            vss.sync_validator_timestamps!
            vss.sync_validator_metadata!
            vss.update_history_height!
          rescue
            log.report_error $!
            log.end && next if $!.is_a?(Cosmos::SyncBase::CriticalError)
            puts "Failed to complete validator sync!\n#{$!.message}"
            puts $!.backtrace.join("\n") && puts if ENV['DEBUG']
          end

          begin
            log.set_status 'validator-events'
            ves = Cosmos::ValidatorEventsService.new(chain)
            ves.run!
          rescue
            log.report_error $!
            log.end && next if $!.is_a?(Cosmos::SyncBase::CriticalError)
            puts "Failed to complete events sync!\n#{$!.message}"
            puts $!.backtrace.join("\n") && puts if ENV['DEBUG']
          end

          begin
            log.set_status 'faucet'
            fss = Cosmos::FaucetSyncService.new(chain)
            fss.sync_token_info!
          rescue
            log.report_error $!
            log.end && next if $!.is_a?(Cosmos::SyncBase::CriticalError)
            puts "Failed to complete faucet sync!\n#{$!.message}"
            puts $!.backtrace.join("\n") && puts if ENV['DEBUG']
          end

          log.set_status 'done'
          log.end
        end
      end
      puts "Completed sync:cosmos:all task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}\n\n"
    end

    desc 'Sync blocks'
    task blocks: :environment do
      puts "\nStarting sync:cosmos:blocks task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
      Cosmos::Chain.enabled.find_each do |chain|
        TaskLock.with_lock!(:sync, chain.id) do
          begin
            Cosmos::BlockSyncService.new(chain).sync!
          rescue
            puts "Failed to complete block sync!\n#{$!.message}\n#{$!.backtrace.join("\n")}\n"
          end
        end
      end
      puts "Completed sync:cosmos:blocks task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}\n\n"
    end

    desc 'Sync validators (create new, update timestamps, etc)'
    task validators: :environment do
      puts "\nStarting sync:cosmos:validators task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
      Cosmos::Chain.enabled.find_each do |chain|
        TaskLock.with_lock!(:sync, chain.id) do
          begin
            vss = Cosmos::ValidatorSyncService.new(chain)
            vss.sync_validator_timestamps!
            vss.sync_validator_metadata! if chain.enabled?
            vss.update_history_height!
          rescue
            puts "Failed to complete validator sync!\n#{$!.message}\n#{$!.backtrace.join("\n")}\n"
          end
        end
      end
      puts "Completed sync:cosmos:validators task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}\n\n"
    end

    desc 'Sync faucets'
    task faucets: :environment do
      puts "\nStarting sync:cosmos:faucets task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
      Cosmos::Chain.enabled.find_each do |chain|
        next unless chain.faucet
        TaskLock.with_lock!(:sync, chain.id) do
          begin
            fss = Cosmos::FaucetSyncService.new(chain)
            fss.sync_token_info!
          rescue
            puts "Failed to complete faucet sync!\n#{$!.message}\n#{$!.backtrace.join("\n")}\n"
          end
        end
      end
      puts "Completed sync:cosmos:faucets task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}\n\n"
    end

    desc 'Sync governance & proposals'
    task gov: :environment do
      puts "\nStarting sync:cosmos:gov task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
      Cosmos::Chain.enabled.find_each do |chain|
        TaskLock.with_lock!(:sync, chain.id) do
          begin
            Cosmos::GovSyncService.new(chain).sync!
          rescue
            puts "Failed to complete governance sync!\n#{$!.message}\n#{$!.backtrace.join("\n")}\n"
          end
        end
      end
      puts "Completed sync:cosmos:gov task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}\n\n"
    end

    task 'Determine validator events to log'
    task events: :environment do
      puts "\nStarting task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
      Cosmos::Chain.enabled.find_each do |chain|
        TaskLock.with_lock!(:sync, chain.id) do
          begin
            ves = Cosmos::ValidatorEventsService.new(chain)
            ves.run!
          rescue
            puts "Failed to complete events sync!\n#{$!.message}\n#{$!.backtrace.join("\n")}\n"
          end
        end
      end
      puts "Completed task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}\n\n"
    end

  end
end
