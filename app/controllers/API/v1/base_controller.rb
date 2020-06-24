class API::V1::BaseController < ApplicationController
  skip_before_action :http_basic_auth
  skip_before_action :get_user

  respond_to :json
end