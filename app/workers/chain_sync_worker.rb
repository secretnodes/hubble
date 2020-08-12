class ChainSyncWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync, retry: false, backtrace: true

  def perform(network='secret')
    network.titleize.constantize::Chain.enabled.find_each do |chain|
      TaskLock.with_lock!(:sync, "#{network}-#{chain.ext_id}") do
        log = Stats::SyncLog.start( chain )

        begin
          bss = chain.namespace::BlockSyncService.new(chain)
          log.set_status 'blocks'
          bss.sync!
        rescue
          log.report_error $!
          log.end && next if $!.is_a?(chain.namespace::SyncBase::CriticalError)
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
        end

        begin
          log.set_status 'halt-check'
          hcs = chain.namespace::HaltedChainService.new(chain)
          hcs.check_for_halted_chain!
        rescue
          log.report_error $!
          log.end && next if $!.is_a?(chain.namespace::SyncBase::CriticalError)
        end

        if !chain.halted?
          begin
            log.set_status 'validators'
            vss = chain.namespace::ValidatorSyncService.new(chain)
            vss.sync_validator_timestamps!
            vss.sync_validator_metadata!
            vss.update_history_height!
          rescue
            log.report_error $!
            log.end && next if $!.is_a?(chain.namespace::SyncBase::CriticalError)
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
        end

        begin
          log.set_status 'cleanup'
          # bss.cleanup!
        rescue
          log.report_error $!
          log.end
        end

        log.set_status 'done'
        log.end
      end
    end
  rescue
    log.report_error $!
  ensure
    workers = Sidekiq::Workers.new
    if workers.select { |w| w[2]['payload']['class'] == 'ChainSyncWorker' }.size < 2
      ChainSyncWorker.perform_in(1.second, network)
    end
  end
end