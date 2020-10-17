class Admin::AlertSubscriptionsController < Admin::BaseController
  load_and_authorize_resource
  def destroy
    sub = AlertSubscription.find params[:id]
    sub.destroy
    redirect_to admin_user_path( sub.user )
  end

end
