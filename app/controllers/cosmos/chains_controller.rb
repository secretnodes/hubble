class Cosmos::ChainsController < Cosmos::BaseController
  before_action :ensure_chain, only: %i{ show }

  def index
    @chains = Cosmos::Chain.order( 'last_sync_time DESC, created_at DESC' )
  end

  def show
    @validators = @chain.validators
    @governance = @chain.governance
    page_title 'Cosmos', @chain.name, 'Overview'

    if @latest_block.nil?
      redirect_to prestart_cosmos_chain_path(@chain)
    end
  end

  def halted
    if action_name == 'halted' && !(@chain.halted? || Rails.env.development?)
      redirect_to cosmos_chain_path(@chain)
      return
    end
    render template: 'cosmos/chains/halted'
  end
  alias :prestart :halted
end
