class FinalizePetitionWorker
  include Sidekiq::Worker
  sidekiq_options queue: :alerts, retry: false, backtrace: true

  def perform(petition_id, chain_class, chain_id)
    chain = chain_class.constantize.find chain_id
    petition = chain.petitions.find petition_id

    if petition.voting_end_time <= Time.now
      status = petition.tally_result_yes > petition.tally_result_no ? :passed : :rejected
      petition.update finalized: true, status: status
    end
  end
end