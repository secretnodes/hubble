class Admin::MainController < Admin::BaseController
  load_and_authorize_resource class: 'Secret::Chain'

  def index
  end

end
