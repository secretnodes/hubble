namespace :backfill_genesis_accounts do
  %w{ secret enigma cosmos terra iris kava }.each do |network|
    task :"#{network.to_sym}" => :environment do
      $stdout.sync = true
      puts "\nStarting sync:#{network} task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"

      network.titleize.constantize::Chain.enabled.find_each do |chain|
        syncer = chain.syncer
        genesis = syncer.get_genesis
        accounts = genesis['result']['genesis']['app_state']['auth']['accounts']
        accounts.each do |account|
          next unless account['type'] == 'cosmos-sdk/Account'

          address = account['value']['address']
          chain.accounts.find_or_create_by(address: address)
        end
      end
    end
  end
end