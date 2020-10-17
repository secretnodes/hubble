class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include ApplicationHelper
  include NamespacedChainsHelper
  include AdminHelper
  include ActionView::Helpers::DateHelper

  before_action :http_basic_auth if REQUIRE_HTTP_BASIC
  before_action :configure_permitted_parameters, if: :devise_controller?


  rescue_from CanCan::AccessDenied do |exception|
    if current_user.blank?
      flash[:info] = 'You must be logged in to use this feature. Please login and try again.'
    else
      flash[:error] = 'You are not authorized to use this feature.'
    end

    redirect_back(fallback_location: root_path)
  end

  if !Rails.env.development?
    rescue_from StandardError,
                  with: :render_500
    rescue_from ActionController::Denied,
                ActionController::InvalidAuthenticityToken,
                  with: :render_403
    rescue_from ActionController::RoutingError,
                AbstractController::ActionNotFound,
                ActionView::MissingTemplate,
                ActionController::NotFound,
                ActiveRecord::RecordNotFound,
                  with: :render_404
  end

  def append_info_to_payload(payload)
    super
    payload[:uid] = current_user.try(:id)
    payload[:aid] = current_admin.try(:id)
    payload[:user_agent] = request.env['HTTP_USER_AGENT']
  end

  private

  def params_return_path
    params[:return_path].blank? ? nil : params[:return_path]
  end

  def http_basic_auth
    whitelisted_ip = request.ip.in?([])
    return true if whitelisted_ip

    authenticate_or_request_with_http_basic do |username, password|
      username == HTTP_BASIC_USERNAME &&
      password == HTTP_BASIC_PASSWORD
    end
  end

  def render_404( e=nil )
    logger.error( "#{e.message} : #{e.backtrace.first rescue nil}" ) if e
    respond_to do |format|
      format.html {
        render template: '/errors/404', status: 404, layout: 'errors'
      }
      format.json {
        render json: { error: 404, message: 'not found' }, status: 404
      }
      format.any {
        render body: '', status: 404, content_type: 'text/plain'
      }
    end
  end

  def render_403( e=nil )
    logger.error( "#{e.message} : #{e.backtrace.first rescue nil}" ) if e
    respond_to do |format|
      format.html {
        render template: '/errors/403', status: 403, layout: 'errors'
      }
      format.json {
        render json: { error: 403, message: 'forbidden' }, status: 403
      }
      format.any {
        render body: '', status: 403, content_type: 'text/plain'
      }
    end
  end

  def render_500( e=nil )
    logger.error( "\nRENDER_500!\n\n" + e.message + "\n" + e.backtrace.join("\n") + "\n" )
    respond_to do |format|
      format.html {
        render template: '/errors/500', status: 500, layout: 'errors'
      }
      format.json {
        render json: { error: 500, message: 'server error' }, status: 500
      }
      format.any {
        render body: '', status: 500, content_type: 'text/plain'
      }
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end
end
