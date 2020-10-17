module AdminHelper
  def current_admin
    if @_current_admin.nil? && current_user&.sudo?
      @_current_admin ||= current_user
      Rails.logger.debug "Admining as #{@_current_admin.try(:email).inspect}"
    end
    @_current_admin
  end
end
