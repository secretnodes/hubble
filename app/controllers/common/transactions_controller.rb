class Common::TransactionsController < Common::BaseController

  def index
    @transactions = @chain.namespace::Transaction.paginate(page: params[:page], per_page: 50)
    @decorated_txs = @transactions.map { |tr| @chain.namespace::TransactionDecorator.new(@chain, tr) }
    # @blocks = @chain.namespace::Block.where.not(transactions: nil).paginate(page: params[:page], per_page: 25)
    @transactions_total = @transactions.count
  end

  def show
    begin
      transaction = @chain.namespace::Transaction.find_by_hash_id params[:id]
      @decorated_tx = @chain.namespace::TransactionDecorator.new( @chain, transaction )
      @block = @chain.blocks.find_by( height: transaction.height ) ||
               @namespace::Block.stub( @chain, transaction.height )
    rescue
      @error = true
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

end
