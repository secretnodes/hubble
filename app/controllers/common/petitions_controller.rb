class Common::PetitionsController < Common::BaseController
  before_action :ensure_chain

  def index
    @petitions = @chain.namespace::Petition.ordered_by_submit_time

    page_title @chain.network_name, @chain.name, 'Governance Petitions & Results'
    meta_description "#{@chain.network_name} -- #{@chain.name} Governance Petitions: Title, Status, Date Submitted, and Petition Parameters"
  end

  def new
    @petition = @chain.namespace::Petition.new
  end

  def create
    end_date = petition_params[:voting_end_time].to_i.days.from_now
    @petition = @chain.petitions.new(
      petition_params.merge(
        voting_start_time: Time.now,
        voting_end_time: end_date,
        status: :voting_period
      )
    )

    if @petition.save!
      FinalizePetitionWorker.perform_at(end_date, @petition.id, @chain)
      flash[:success] = "You successfully created a petition entitled #{@petition.title}!"
      return
    else
      flash[:error] = "There was an error creating your petition. Please try again."
      return
    end
  end

  private
  
  def petition_params
    params.require("#{@chain.namespace.to_s.downcase}_petition".to_sym).permit(
      :title,
      :voting_end_time,
      :description
    )
  end
end