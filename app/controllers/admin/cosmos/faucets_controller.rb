class Admin::Cosmos::FaucetsController < Admin::Common::FaucetsController
  protected

  def ensure_chain
    @chain = ::Cosmos::Chain.find_by( slug: params[:chain_id] )
  end
end
