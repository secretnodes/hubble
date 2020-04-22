class Admin::Enigma::FaucetsController < Admin::Common::FaucetsController
  protected

  def ensure_chain
    @chain = ::Enigma::Chain.find_by( slug: params[:chain_id] )
  end
end
