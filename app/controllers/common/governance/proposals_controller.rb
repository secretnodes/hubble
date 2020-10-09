class Common::Governance::ProposalsController < Common::BaseController
  before_action :ensure_chain

  def show
    @proposal = @chain.governance_proposals.find_by(ext_id: params[:id])
    @tally_result = @chain.namespace::ProposalTallyDecorator.new(@proposal)
    
    @comments = @proposal.comments

    page_title @chain.network_name, @chain.name, @proposal.title
    meta_description @proposal.description.truncate(160, separator: '...')

    render template: 'common/governance/proposal'
  end
end
