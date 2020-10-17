class Admin::SessionsController < Admin::BaseController

  def new
    if params[:token]
      a = Administrator.find_by one_time_setup_token: params[:token]
      if a
        session[:admin_id] = a.id
        redirect_to setup_admin_administrators_path( first: true )
        return
      end
      raise ActionController::RoutingError
    end
  end

  def create
    params[:email] = params[:email].downcase
    a = Administrator.where( email: params[:email].downcase ).first

    if a &&
       a.authenticate( params[:password] )
      #  (!a.otp_secret_key? || Rails.env.development? || a.authenticate_otp(params[:otp_code]))
      session[:admin_id] = a.id
      cookies.signed[:admin_id] = a.id
      if !a.otp_secret_key?
        redirect_to setup_admin_administrators_path
        return
      end
    else
      flash[:error] = "Invalid login."
    end
    redirect_to session[:after_admin_login_path] || admin_root_path
  end

  def destroy
    redirect_to destroy_user_session_path
  end

end
