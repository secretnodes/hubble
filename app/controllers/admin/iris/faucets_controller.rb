class Admin::Iris::FaucetsController < Admin::Common::FaucetsController
  protected

  def ensure_chain
    @chain = ::Iris::Chain.find_by( slug: params[:chain_id] )
  end
end
