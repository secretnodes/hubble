namespace :backfill_db_transactions do
  %w{ secret enigma cosmos terra iris kava }.each do |network|
    task :"#{network.to_sym}" => :environment do
      $stdout.sync = true
      puts "\nStarting sync:#{network} task at #{Time.now.utc.strftime(TASK_DATETIME_FORMAT)}"
      network.titleize.constantize::Chain.enabled.find_each do |chain|
        syncer = chain.syncer
        blocks = chain.blocks.where.not(transactions: nil).reverse

        blocks.each do |block|
          txs = block.transactions.map { |hash| syncer.get_transaction(hash) }
          txs.each do |tx|
            begin
              chain.namespace::Transaction.assemble(chain, block, tx)
            rescue RuntimeError => e
              puts e
              next
            end
          end
        end
      end
    end
  end
end