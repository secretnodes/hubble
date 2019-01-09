class Cosmos::Governance::MainController < Cosmos::BaseController
  before_action :ensure_chain

  def index
    @proposals = @chain.governance_proposals.ordered_by_submit_time
    render template: 'cosmos/governance/index'
  end
end
