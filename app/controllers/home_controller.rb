class HomeController < ApplicationController
  layout 'account'

  def index
    page_title 'puzzle'
  end

  def catch_404
    raise ActionController::RoutingError.new(params[:path])
  end
end
