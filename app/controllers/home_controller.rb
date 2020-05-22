class HomeController < ApplicationController
  layout 'account'

  def index
    page_title 'Puzzle'
  end

  def catch_404
    raise ActionController::RoutingError.new(params[:path])
  end

  def privacy_policy
    page_title 'Puzzle Privacy Policy'
  end
end
