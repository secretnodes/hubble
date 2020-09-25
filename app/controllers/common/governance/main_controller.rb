class Common::Governance::MainController < Common::BaseController
  before_action :ensure_chain

  def index
    @proposals = @chain.governance_proposals.ordered_by_voting_start_time

    page_title @chain.network_name, @chain.name, 'Governance Proposals & Results'
    meta_description "#{@chain.network_name} -- #{@chain.name} Governance Proposals: Title, Status, Date Submitted, and Proposal Parameters"

    render template: 'common/governance/index'
  end
end
