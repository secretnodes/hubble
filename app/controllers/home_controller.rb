class HomeController < ApplicationController
  def index
    redirect_to cosmos_chain_path( Cosmos::Chain.primary )
  end

  def catch_404
    raise ActionController::RoutingError.new(params[:path])
  end
end
