class Cosmos::FaucetsController < Cosmos::BaseController
  before_action :ensure_chain

  def show
    @faucet = @chain.faucet
    unless @faucet
      redirect_to cosmos_chain_path(@chain)
      return
    end
  end
end
