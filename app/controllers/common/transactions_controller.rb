class Common::TransactionsController < Common::BaseController
  before_action :ensure_chain

  def index
    @page = params[:page] || 1
    chain_ids = @chain.namespace::Chain.where(testnet: @chain.testnet?).pluck(:id)
    @transactions = @chain.namespace::Transaction.where(chain_id: chain_ids).reorder(timestamp: :desc).paginate(page: @page, per_page: 50)
    @decorated_txs = @transactions.map { |tr| @chain.namespace::TransactionDecorator.new(tr.chain, tr, tr.hash_id) }
    @transactions_total = @transactions.count
    @type = 'transactions'

    if params[:partial] == "true"
      render partial: 'transactions_table', locals: { transactions: @transactions, decorated_txs: @decorated_txs, transactions_total: @transactions_total, type: @type, page: @page }
      return
    end
  end

  def show
    begin
      transaction = @chain.txs.find_by_hash_id params[:id]
      @decorated_tx = @chain.namespace::TransactionDecorator.new( transaction.chain, transaction, params[:id] )
      @block = @chain.blocks.find_by( height: @decorated_tx.height ) ||
               @namespace::Block.stub( @chain, @decorated_tx.height )
    end

    respond_to do |format|
      format.html {
        page_title @chain.network_name, @chain.name, "Tx #{@transaction.hash}"
      }
      format.json do
        render json: @error ? { ok: false } : @decorated_tx.dump
      end
    end
  end

  def swaps
    @page = params[:page] || 1
    chain_ids = @chain.namespace::Chain.where(testnet: @chain.testnet?).pluck(:id)
    @raw_transactions = @chain.namespace::Transaction.swap.where(chain_id: chain_ids).reorder(timestamp: :desc)
    @transactions = @raw_transactions.paginate(page: @page, per_page: 50)
    @decorated_txs = @transactions.map { |tr| @chain.namespace::TransactionDecorator.new(tr.chain, tr, tr.hash_id) }
    @transactions_total = @transactions.count
    @swap_address_count = @chain.namespace::Transaction.swap_address_count
    @total_swaps_data = @chain.namespace::Transaction.unscoped.where(transaction_type: :swap, chain_id: chain_ids).group_by_day(:timestamp).count.to_json
    @type = 'swaps'

    @total_swap = 0
    @raw_transactions.each do |tx|
      @total_swap += tx.message[0]['value']['AmountENG'].to_f
    end

    if params[:partial] == "true"
      render partial: 'transactions_table', locals: { transactions: @transactions, decorated_txs: @decorated_txs, transactions_total: @transactions_total, type: @type, page: @page }
    else
      render 'index'
    end
  end

  def contracts
    @page = params[:page] || 1
    chain_ids = @chain.namespace::Chain.where(testnet: @chain.testnet?).pluck(:id)

    @raw_transactions = @chain.namespace::Transaction.where(
      chain_id: chain_ids,
      transaction_type: [:store_contract_code, :initialize_contract, :execute_contract]
    ).reorder(timestamp: :desc)

    @transactions = @raw_transactions.paginate(page: @page, per_page: 50)
    @decorated_txs = @transactions.map { |tr| @chain.namespace::TransactionDecorator.new(tr.chain, tr, tr.hash_id) }

    @transactions_total = @raw_transactions.count
    @deployed_total = @raw_transactions.store_contract_code.where(error_message: nil).count
    @executions_total = @raw_transactions.execute_contract.where(error_message: nil).count
    
    @total_contracts_data = @chain.namespace::Transaction.unscoped.where(
      chain_id: chain_ids,
      transaction_type: [:store_contract_code, :initialize_contract, :execute_contract]
    ).group_by_day(:timestamp).count.to_json

    @type = 'contracts'

    @total_contracts = 0

    if params[:partial] == "true"
      render partial: 'transactions_table', locals: { transactions: @transactions, decorated_txs: @decorated_txs, transactions_total: @transactions_total, type: @type, page: @page }
    else
      render 'index'
    end
  end
end
