class Common::DashboardController < Common::BaseController
  before_action :require_user
  before_action :ensure_chain

  def index
    page_title @chain.network_name, @chain.name, 'Dashboard'
    # raise ActionController::NotFound unless current_admin
  end

end
