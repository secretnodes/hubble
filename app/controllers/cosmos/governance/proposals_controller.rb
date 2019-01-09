class Cosmos::Governance::ProposalsController < Cosmos::BaseController
  before_action :ensure_chain

  def show
    @proposal = @chain.governance_proposals.find_by(chain_proposal_id: params[:id])
    @tally_result = Cosmos::ProposalTallyDecorator.new(@proposal)
    render template: 'cosmos/governance/proposal'
  end
end
