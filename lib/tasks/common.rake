namespace :common do

  task clean_daily_sync_logs: :environment do
    TaskLock.with_lock!( :cleanup ) do
      puts "Starting daily sync log cleaning task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
      to_clean = Stats::SyncLog.last
      while (to_clean && to_clean.started_at < Time.now.utc.beginning_of_day)
        # bucket all other synclogs from that day
        start_time = to_clean.started_at.beginning_of_day
        end_time = to_clean.started_at.end_of_day

        puts "TO CLEAN: #{start_time}"

        bucket = Stats::SyncLog.where(
          'started_at >= ? AND started_at <= ?',
          start_time, end_time
        ).group_by { |sl| sl.chain }

        bucket.keys.each do |chain|
          Stats::DailySyncLog.create_from bucket[chain]
        end

        to_clean = Stats::SyncLog.where( 'started_at > ?', end_time ).last
      end
      puts "Completed daily sync log cleaning task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}\n\n"
    end
  end

end
