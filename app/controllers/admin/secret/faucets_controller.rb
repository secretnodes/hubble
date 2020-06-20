class Admin::Secret::FaucetsController < Admin::Common::FaucetsController
  protected

  def ensure_chain
    @chain = ::Secret::Chain.find_by( slug: params[:chain_id] )
  end
end
