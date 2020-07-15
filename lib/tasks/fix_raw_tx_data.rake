namespace :fix_raw_tx_data do
  %w{ secret enigma cosmos terra iris kava }.each do |network|
    task :"#{network.to_sym}" => :environment do
      $stdout.sync = true
      puts "\nStarting sync:#{network} task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
      network.titleize.constantize::Chain.enabled.find_each do |chain|
        transactions = chain.transactions
        syncer = chain.syncer
        transactions.each do |tx|
          raw_data = syncer.get_transaction(tx.hash_id)
          tx.update raw_transaction: raw_data
        end
      end
    end
  end
end