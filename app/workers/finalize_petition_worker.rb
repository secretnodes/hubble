class FinalizePetitionWorker
  include Sidekiq::Worker
  sidekiq_options queue: :alerts, retry: false, backtrace: true

  def perform(petition_id, chain)
    petition = chain.petitions.find petition_id

    if petition.voting_end_time <= Time.now
      petition.update finalized: true
    end
  end
end