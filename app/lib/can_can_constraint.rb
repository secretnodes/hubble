class CanCanConstraint
  def initialize(action, resource)
      @action = action
      @resource = resource
  end

  def matches?(request)
      if request.session['user_id'].present?
          current_user = User.find(request.session['user_id'])
          ability = Ability.new(current_user)
          return ability.can?(@action, @resource)
      else
          return false
      end
  end
end