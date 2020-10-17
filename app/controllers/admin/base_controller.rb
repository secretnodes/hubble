class Admin::BaseController < ApplicationController
  include AdminHelper

  # before_action :require_2fa

  around_action :set_timezone, if: -> { current_admin.present? }
  layout 'admin'

  rescue_from CanCan::AccessDenied do |exception|
    if current_user.blank?
      flash[:info] = 'You must be logged in to use this feature. Please login and try again.'
    else
      flash[:error] = 'You are not authorized to use this feature.'
    end

    redirect_back(fallback_location: root_path)
  end

  private
  
  def current_admin
    @current_admin ||= current_user if current_user&.sudo?
  end

  def current_ability
    # I am sure there is a slicker way to capture the controller namespace
    controller_name_segments = params[:controller].split('/')
    controller_name_segments.pop
    controller_namespace = controller_name_segments.join('/').camelize
    @current_ability ||= Ability.new(current_user, controller_namespace)
  end

  # def require_2fa
  #   return if helpers.current_admin.nil?
  #   if helpers.current_admin.one_time_setup_token?
  #     session[:after_admin_login_path] = request.fullpath
  #     redirect_to setup_admin_administrators_path
  #     return false
  #   end
  # end

  def set_timezone( &block )
    Rails.logger.debug "SETTING TIMEZONE TO EST FOR ADMIN"
    Time.use_zone( 'Eastern Time (US & Canada)', &block )
  end
end
