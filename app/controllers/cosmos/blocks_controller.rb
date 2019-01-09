class Cosmos::BlocksController < Cosmos::BaseController
  before_action :ensure_chain

  def show
    @block = @chain.blocks.find_by( height: params[:id] ) ||
             Cosmos::Block.stub_from_cache( @chain, params[:id] )

    respond_to do |format|
      format.html {}
      format.json do
        begin
          case params[:kind]
          when 'commit'
            render json: Cosmos::SyncBase.new(@chain).get_commit( @block.height )
          when 'block'
            render json: Cosmos::SyncBase.new(@chain).get_block( @block.height )
          when 'set'
            render json: @block.validator_set
          else
            render json: { error: "Unknown json #{params[:kind].inspect}." }
          end
        rescue
          render json: { error: 'Internal Server Error', status: 500 }
        end
      end
    end
  end

end
