class Cosmos::BaseController < ApplicationController
  before_action :get_chain_from_route
  before_action :set_behind_chain_alert

  protected

  def set_behind_chain_alert
    return unless @chain
    @latest_block = @chain.blocks.first
    @latest_sync = @chain.sync_logs.completed.first || @chain.daily_sync_logs.first

    @is_syncing = @latest_sync && @latest_sync.timestamp > 4.minutes.ago
    @chain_stopped = @latest_block ? @is_syncing && @latest_block.timestamp < 4.minutes.ago : false
  end

  def get_chain_from_route
    @chain = Cosmos::Chain.find_by( slug: params[:chain_id] || params[:id] )
  end

  def ensure_chain
    raise ActiveRecord::RecordNotFound unless @chain
  end
end
