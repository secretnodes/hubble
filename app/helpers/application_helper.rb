module ApplicationHelper
  def js_namespace
    obj = {
      # data
      mode: [],
      seed: {},
      config: {},

      # class namespaces
      Stats: {},
      Cosmos: {}
    }

    javascript_tag "window.App = #{obj.to_json.html_safe};"
  end

  def page_title?
    !!@_page_title
  end
  def page_title( *set )
    if set.any?
      set << 'Hubble (by Figment Networks)'
      @_page_title = set.join ' - '
    end
    @_page_title
  end

  def monitor_body_classes( *set )
    if @chain
      set << "#{@chain.slug}-chain"
    end
    @_monitor_body_classes = set.join ' ' if set.any?
    @_monitor_body_classes || ''
  end

  def current_ip
    request.try(:remote_ip)
  end
  def current_user
    @current_user
  end

  def should_show_login_links?
    controller_name == 'sessions' ||
    controller_name == 'users'
  end

  def get_user
    if session[:masq]
      if session[:masq].to_i < Time.now.to_i
        session.delete :masq
        session.delete :uid
      else
        logger.debug "LOGIN-AS: you had #{session[:masq].to_i - Time.now.to_i} seconds remaining"
        session[:masq] = User::MASQ_TIMEOUT.from_now.to_i
      end
    end
    if session.has_key?(:uid) && @current_user.nil?
      @current_user = User.find_by_id(session[:uid])
      @current_user = nil if @current_user.try(:deleted?)
      if @current_user && !session[:masq]
        # dont bother parsing ua here, just on login
        @current_user.update_for_request( ua: nil, ip: current_ip )
      end
      logger.debug "#{session[:masq] ? 'Masquerading' : 'Authenticated'} as #{@current_user.try(:email).inspect}"
    end
  end

  def require_user( user=nil )
    unless current_user && (user.nil? || current_user.id == user.id)
      if request.xhr?
        render json: { ok: false, url: login_path( return_path: request.fullpath ) }, status: 403
        return false
      else
        flash[:error] = "We couldn't show you that page for some reason. You might have been logged out, so login below and try again."
        redirect_to login_path( return_path: request.fullpath )
        return false
      end
    end
  end
end
