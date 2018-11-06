namespace :stats do
  namespace :cosmos do
    task all: :environment do
      TaskLock.with_lock!( :cosmos, :stats ) do
        puts "Starting Cosmos stats task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
        Cosmos::Chain.find_each do |chain|
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
        puts "Completed Cosmos stats task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}\n\n"
      end
    end
  end
end
