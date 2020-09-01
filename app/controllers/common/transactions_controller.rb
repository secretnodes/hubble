class Common::TransactionsController < Common::BaseController

  def index
    @page = params[:page] || 1
    @transactions = @chain.namespace::Transaction.paginate(page: @page, per_page: 50)
    @decorated_txs = @transactions.map { |tr| @chain.namespace::TransactionDecorator.new(@chain, tr, tr.hash_id) }
    @transactions_total = @transactions.count
    @type = 'transactions'

    if params[:partial] == "true"
      render partial: 'transactions_table', locals: { transactions: @transactions, decorated_txs: @decorated_txs, transactions_total: @transactions_total, type: @type, page: @page }
      return
    end
  end

  def show
    begin
      transaction = @chain.namespace::Transaction.find_by_hash_id params[:id]
      @decorated_tx = @chain.namespace::TransactionDecorator.new( @chain, transaction, params[:id] )
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
    @raw_transactions = @chain.namespace::Transaction.swap
    @transactions = @raw_transactions.paginate(page: @page, per_page: 50)
    @decorated_txs = @transactions.map { |tr| @chain.namespace::TransactionDecorator.new(@chain, tr, tr.hash_id) }
    @transactions_total = @transactions.count
    @swap_address_count = @chain.namespace::Transaction.swap_address_count
    @total_swaps_data = @chain.namespace::Transaction.unscoped.where(transaction_type: :swap).group_by_day(:timestamp).count.to_json
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
end
