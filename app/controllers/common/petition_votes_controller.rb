class Common::PetitionVotesController < Common::BaseController
  before_action :ensure_chain
  load_and_authorize_resource

  def create
    petition = @chain.petitions.find params[:petition_id]

    vote = @chain.namespace::PetitionVote.where(user_id: current_user.id, petition_id: petition.id).first_or_initialize
    vote.option = params[:vote_options].downcase

    if vote.save
      flash[:notice] = "You successfully voted #{params[:vote_option]} on this petition!"
      redirect_back(fallback_location: namespaced_path('petitions'))
    else
      flash[:error] = "There was an error recording your vote. Please try again."
      redirect_back(fallback_location: namespaced_path('petitions'))
    end
  end
end