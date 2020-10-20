class Common::Governance::MainController < Common::BaseController
  before_action :ensure_chain

  def index
    if params[:type] == 'petitions'
      @petitions = @chain.namespace::Petition.petition.ordered_by_submit_time
      @pet_active = 'active'
    elsif params[:type] == 'foundation'
      @petitions = @chain.namespace::Petition.foundation.ordered_by_submit_time
      @f_active = 'active'
    else
      @proposals = @chain.governance_proposals.ordered_by_submit_time
      @prop_active = 'active'
    end
    

    page_title @chain.network_name, @chain.name, 'Governance Proposals & Results'
    meta_description "#{@chain.network_name} -- #{@chain.name} Governance Proposals: Title, Status, Date Submitted, and Proposal Parameters"

    render template: 'common/governance/index'
  end
end
