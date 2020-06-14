namespace :sync do
  task :all do
    %w{ enigma cosmos terra iris kava }.each do |network|
      Rake::Task["sync:#{network}"].invoke
    end
  end

  %w{ enigma cosmos terra iris kava }.each do |network|
    task :"#{network.to_sym}" => :environment do
      $stdout.sync = true
      puts "\nStarting sync:#{network} task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
      network.titleize.constantize::Chain.enabled.find_each do |chain|
        TaskLock.with_lock!(:sync, "#{network}-#{chain.ext_id}") do
          log = Stats::SyncLog.start( chain )

          begin
            bss = chain.namespace::BlockSyncService.new(chain)
            log.set_status 'blocks'
            bss.sync!
            puts "got past bss sync"
          rescue
            log.report_error $!
            log.end && next if $!.is_a?(chain.namespace::SyncBase::CriticalError)
            puts "Failed to complete block sync!\n#{$!.message}"
            puts $!.backtrace.join("\n") && puts if ENV['DEBUG']
          end

          begin
            log.set_status 'governance'
            gss = chain.namespace::GovSyncService.new(chain)
            gss.sync_params!
            gss.sync_pool!
            gss.sync_proposals!
            gss.sync_token_stats!
          rescue
            log.report_error $!
            log.end && next if $!.is_a?(chain.namespace::SyncBase::CriticalError)
            puts "Failed to complete governance sync!\n#{$!.message}"
            puts $!.backtrace.join("\n") && puts if ENV['DEBUG']
          end

          begin
            log.set_status 'halt-check'
            hcs = chain.namespace::HaltedChainService.new(chain)
            hcs.check_for_halted_chain!
          rescue
            log.report_error $!
            log.end && next if $!.is_a?(chain.namespace::SyncBase::CriticalError)
            puts "Failed to complete halt check!\n#{$!.message}"
            puts $!.backtrace.join("\n") && puts if ENV['DEBUG']
          end

          if !chain.halted?
            begin
              log.set_status 'validators'
              vss = chain.namespace::ValidatorSyncService.new(chain)
              vss.sync_validator_timestamps!
              vss.sync_validator_metadata!
              puts 'before history height'
              vss.update_history_height!
              puts 'after history height'
            rescue
              log.report_error $!
              log.end && next if $!.is_a?(chain.namespace::SyncBase::CriticalError)
              puts "Failed to complete validator sync!\n#{$!.message}"
              puts $!.backtrace.join("\n") && puts if ENV['DEBUG']
            end
          end

          begin
            log.set_status 'validator-events'
            chain = chain.namespace::Chain.find chain.id
            ves = chain.namespace::ValidatorEventsService.new(chain)
            ves.run!
          rescue
            log.report_error $!
            log.end && next if $!.is_a?(chain.namespace::SyncBase::CriticalError)
            puts "Failed to complete events sync!\n#{$!.message}"
            puts $!.backtrace.join("\n") && puts if ENV['DEBUG']
          end

          begin
            log.set_status 'stats'
            stats = chain.namespace::AverageSnapshotsGeneratorService.new( chain )
            stats.generate_block_time_snapshots!
            stats.generate_voting_power_snapshots!
            stats.generate_validator_uptime_snapshots!
            stats.generate_active_validators_snapshots!
          rescue
            log.report_error $!
            log.end
            puts "Failed to collect stats!\n#{$!.message}"
            puts $!.backtrace.join("\n") && puts if ENV['DEBUG']
          end

          begin
            log.set_status 'cleanup'
            # bss.cleanup!
          rescue
            log.report_error $!
            log.end
            puts "Failed to complete block cleanup!\n#{$!.message}"
            puts $!.backtrace.join("\n") && puts if ENV['DEBUG']
          end

          log.set_status 'done'
          log.end
        end
      end
      puts "Completed sync:#{network} task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}\n\n"
    end
  end
end
