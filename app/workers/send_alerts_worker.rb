class SendAlertsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :alerts, retry: false, backtrace: true

  def perform(time_frame='daily')
    $stdout.sync = true
    if time_frame == 'instant'
      TaskLock.with_lock!( :alerts ) do
        Common::AlertSubscriptionNotifier.new( :instant ).run!
      end
    else
      TaskLock.with_lock!( :digests ) do
        date = Time.parse( ENV['DIGEST_DATE'] ) if ENV['DIGEST_DATE']
        date ||= 1.day.ago # yesterday by default
        Common::AlertSubscriptionNotifier.new( :daily, date ).run!
      end
    end
  ensure
    workers = Sidekiq::Workers.new
    if workers.select { |w| w[2]['payload']['class'] == 'SendAlertsWorker' }.size < 2
      SendAlertsWorker.perform_in(1.second, time_frame)
    end
  end
end