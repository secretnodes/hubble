class ExportDuplicateStaysWorker
  include Sidekiq::Worker
  sidekiq_options queue: :balances, retry: false, backtrace: true

  def perform
    puts "hello world"
  end
end