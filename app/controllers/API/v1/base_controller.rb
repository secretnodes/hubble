module Api
  module V1
    class BaseController < ApplicationController
      # skip_before_action :http_basic_auth
      # skip_before_action :get_user

      respond_to :json
    end
  end
end