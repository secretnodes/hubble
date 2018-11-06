class Cosmos::ChainsController < Cosmos::BaseController
  before_action :ensure_chain, only: %i{ show }

  def index
    @chains = Cosmos::Chain.order( 'last_sync_time DESC, created_at DESC' )
  end

  def show
    @validators = @chain.validators
    page_title 'Cosmos', @chain.name, 'Overview'
  end

end
