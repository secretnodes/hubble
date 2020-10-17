class Common::BaseController < ApplicationController
  before_action :get_chain_from_route
  before_action :set_behind_chain_alert

  protected

  def set_behind_chain_alert
    return unless @chain
    @latest_block = @chain.blocks.first
    @latest_sync = @chain.sync_logs.completed.first || @chain.daily_sync_logs.first
    @is_syncing = @latest_sync && @latest_sync.timestamp > 6.minutes.ago
  end

  def get_chain_from_route
    @namespace = self.class.name.split('::').first.constantize
    @chain = @namespace::Chain.find_by( slug: (params[:chain_id] || params[:id]).try(:downcase) )
  end

  def ensure_chain
    raise ActiveRecord::RecordNotFound unless @chain
  end

  def current_ability
    # I am sure there is a slicker way to capture the controller namespace
    controller_name_segments = params[:controller].split('/')
    controller_name_segments.pop
    controller_namespace = controller_name_segments.join('/').camelize
    @current_ability ||= Ability.new(current_user, controller_namespace)
  end
end
