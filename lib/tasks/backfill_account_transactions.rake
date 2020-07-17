namespace :backfill_account_transactions do
  %w{ secret enigma cosmos terra iris kava }.each do |network|
    task :"#{network.to_sym}" => :environment do
      network.titleize.constantize::Chain.enabled.find_each do |chain|
        transactions = chain.txs
        transactions.each do |tx|
          chain.namespace::AccountFinder.new( chain, tx, :transactions ).run
        end
      end
    end
  end
end