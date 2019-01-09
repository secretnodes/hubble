namespace :stats do
  namespace :cosmos do
    task all: :environment do
      puts "Starting Cosmos stats task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
      Cosmos::Chain.enabled.find_each do |chain|
        TaskLock.with_lock!( :stats, chain.id ) do
          # don't collect average stats if the sync is failing
          if chain.failing_sync?
            puts "#{chain.name} is failing sync, no stats collection."
            next
          end

          stats = Cosmos::AverageSnapshotsGeneratorService.new( chain )
          stats.generate_block_time_snapshots!
          stats.generate_voting_power_snapshots!
          stats.generate_validator_uptime_snapshots!
          stats.generate_active_validators_snapshots!
        end
      end
      puts "Completed Cosmos stats task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}\n\n"
    end
  end
end
