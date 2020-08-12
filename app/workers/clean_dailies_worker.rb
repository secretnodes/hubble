class CleanDailiesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :alerts, retry: false, backtrace: true
  def perform
    TaskLock.with_lock!( :cleanup ) do
      to_clean = Stats::SyncLog.last
      while (to_clean && to_clean.started_at < Time.now.utc.beginning_of_day)
        # bucket all other synclogs from that day
        start_time = to_clean.started_at.beginning_of_day
        end_time = to_clean.started_at.end_of_day

        puts "TO CLEAN: #{start_time}"

        bucket = Stats::SyncLog.where(
          'started_at >= ? AND started_at <= ?',
          start_time, end_time
        ).group_by { |sl| sl.chainlike }

        bucket.keys.each do |chain|
          Stats::DailySyncLog.create_from bucket[chain]
        end

        to_clean = Stats::SyncLog.where( 'started_at > ?', end_time ).last
      end
    end
  ensure
    workers = Sidekiq::Workers.new
    if workers.select { |w| w[2]['payload']['class'] == 'CleanDailiesWorker' }.size < 2
      CleanDailiesWorker.perform_in(1.second)
    end
  end
end