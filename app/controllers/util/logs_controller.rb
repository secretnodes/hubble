class Util::LogsController < ApplicationController

  def index
    @chain = Cosmos::Chain.find_by( slug: params[:chain_id] )

    @minutelies = @chain.sync_logs
    @total_minutelies = @minutelies.count
    if !params.has_key?(:all)
      @minutelies = @minutelies.limit( 5 )
    end

    @dailies = @chain.daily_sync_logs
    @total_dailies = @dailies.count
    if !params.has_key?(:all)
      @dailies = @dailies.limit( 6 )
    end
    @dailies = [
      Stats::DailySyncLog.build_from(@chain.sync_logs.today),
      *@dailies
    ].compact
  end

end
