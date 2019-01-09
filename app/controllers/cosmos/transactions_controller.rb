class Cosmos::TransactionsController < Cosmos::BaseController

  def show
    @block = @chain.blocks.find_by( height: params[:block_id] ) ||
             Cosmos::Block.stub( @chain, params[:block_id] )

    begin
      @transaction = Cosmos::TransactionDecorator.new( @chain, params[:id] )
    rescue
      redirect_to cosmos_chain_block_path( @chain, @block )
    end
  end

end
