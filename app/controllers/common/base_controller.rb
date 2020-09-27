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
    @chain = @namespace::Chain.alive.find_by( slug: (params[:chain_id] || params[:id]).try(:downcase) )
  end

  def ensure_chain
    raise ActiveRecord::RecordNotFound unless @chain
  end

  def ensure_current_user
    if current_user.nil?
      flash[:info] = "You must be logged in to use this feature. Please login and try again."
      redirect_back(fallback_location: root_path)
    end
  end
end
