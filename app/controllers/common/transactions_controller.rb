class Common::TransactionsController < Common::BaseController

  def index
    @blocks = @chain.namespace::Block.where.not(transactions: nil).paginate(page: params[:page], per_page: 25)
    @transactions_total = @chain.namespace::Block.where.not(transactions: nil).pluck(:transactions).flatten.count
    @transactions = @blocks.map { |b| b.transaction_objects }.flatten
  end

  def show
    begin
      @transaction = @chain.namespace::TransactionDecorator.new( @chain, params[:id] )
      @block = @chain.blocks.find_by( height: @transaction.height ) ||
               @namespace::Block.stub( @chain, @transaction.height )
    rescue
      @error = true
    end

    respond_to do |format|
      format.html {
        page_title @chain.network_name, @chain.name, "Tx #{@transaction.hash}"
      }
      format.json do
        render json: @error ? { ok: false } : @transaction.dump
      end
    end
  end

end
