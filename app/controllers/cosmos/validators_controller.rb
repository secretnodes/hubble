class Cosmos::ValidatorsController < Cosmos::BaseController
  before_action :ensure_chain

  def show
    @validator = @chain.validators.find_by( address: params[:id] )
    raise ActiveRecord::RecordNotFound unless @validator
    page_title @validator.short_name, @chain.name
  end

end
