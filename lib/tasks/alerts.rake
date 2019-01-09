namespace :alerts do
  namespace :users do
    task instant: :environment do
      TaskLock.with_lock!( :alerts ) do
        Common::AlertSubscriptionNotifier.new( :instant ).run!
      end
    end

    task daily: :environment do
      TaskLock.with_lock!( :alerts ) do
        date = Time.parse( ENV['DIGEST_DATE'] ) if ENV['DIGEST_DATE']
        date ||= 1.day.ago # yesterday by default
        Common::AlertSubscriptionNotifier.new( :daily, date ).run!
      end
    end
  end
end
