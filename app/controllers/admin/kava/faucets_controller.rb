class Admin::Kava::FaucetsController < Admin::Common::FaucetsController
  protected

  def ensure_chain
    @chain = ::Kava::Chain.find_by( slug: params[:chain_id] )
  end
end
