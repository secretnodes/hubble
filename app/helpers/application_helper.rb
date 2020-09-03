module ApplicationHelper
  def js_namespace
    obj = {
      # data
      mode: [],
      seed: {},
      config: {},

      # class namespaces
      Stats: {},
      Common: {}
    }

    if @chain && @chain.primary_token
      primary_token = @chain.primary_token
      obj[:config].merge!(
        network: @chain.network_name,
        denom: @chain.token_map[primary_token]['display'],
        remoteDenom: primary_token,
        remoteScaleFactor: 10 ** @chain.token_map[primary_token]['factor'],
        chainId: @chain.ext_id,
        prefixes: @chain.prefixes,
        startedLate: !@chain.cutoff_at.nil?
      )
    end

    javascript_tag "window.App = #{obj.to_json.html_safe};"
  end

  def page_title?
    !!@_page_title
  end
  def page_title( *set )
    if set.any?
      @_page_title = set.join ' | '
    end
    @_page_title
  end

  def meta_description?
    !!@_meta_description
  end
  def meta_description( text=nil )
    @_meta_description = text if text
    @_meta_description
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
  # def current_user
  #   @current_user
  # end

  def require_user( user=nil )
    unless current_user && (user.nil? || current_user.id == user.id)
      if request.xhr?
        render json: { ok: false, url: login_path( return_path: request.fullpath ) }, status: 403
        return false
      else
        flash[:error] = "We couldn't show you that page for some reason. You might have been logged out, so login below and try again."
        redirect_to sign_in_path
        return false
      end
    end
  end
end
