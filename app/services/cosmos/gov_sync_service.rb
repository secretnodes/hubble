class Cosmos::GovSyncService < Cosmos::SyncBase
  def sync!
    ProgressReport.instance.start "Syncing Governance for Cosmos/#{@chain.name}..."

    sync_governanace_params
    sync_governance_proposals

    ProgressReport.instance.report
  end

  def sync_governanace_params
    return if @chain.governance_params_synced?
    @chain.update_attributes governance: (get_governance||{})
  end

  def sync_governance_proposals
    return if !@chain.governance_params_synced?

    get_proposals.try(:each) do |proposal|
      proposal_details = build_proposal(proposal['value'])

      begin
        working_proposal = @chain.governance_proposals.find_by(
          chain_proposal_id: proposal_details['chain_proposal_id']
        )

        if working_proposal
          puts "Updating Proposal: #{working_proposal.chain_proposal_id} - #{working_proposal.title}"
          working_proposal.update_attributes(proposal_details)
        else
          working_proposal = @chain.governance_proposals.create(proposal_details)
          puts "Synced Proposal: #{working_proposal.chain_proposal_id} - #{working_proposal.title}"
        end

        sync_governance_proposal_deposits(working_proposal)
        sync_governance_proposal_votes(working_proposal)
        sync_governance_proposal_tallies(working_proposal)
      end
    end
  end

  def sync_governance_proposal_tallies(hubble_proposal)
    tally = get_proposal_tally(hubble_proposal.chain_proposal_id)
    return if tally.nil?

    hubble_proposal.update_attributes(
      tally_result_yes: tally['yes'],
      tally_result_no: tally['no'],
      tally_result_abstain: tally['abstain'],
      tally_result_nowithveto: tally['no_with_veto']
    )
  end

  def sync_governance_proposal_deposits(hubble_proposal)
    deposits = get_proposal_deposits(hubble_proposal.chain_proposal_id)
    return if deposits.nil?

    deposits.each do |deposit|
      address = deposit['depositer'] || deposit['depositor']
      account = @chain.accounts.find_or_create_by( address: address )

      deposit['amount'].try(:each) do |deposit_amount|
        amount_denom = deposit_amount['denom']
        amount = deposit_amount['amount'].to_i

        deposit = Cosmos::Governance::Deposit.find_or_create_by(
          account: account,
          proposal: hubble_proposal,
          amount_denom: amount_denom,
          amount: amount
        ) do |d|
          puts "Deposit by #{account.address} recorded against #{hubble_proposal.title}"
        end

        if !deposit.valid? || !deposit.persisted?
          puts "Invalid deposit #{deposit_amount.inspect} for proposal #{hubble_proposal.title} -- #{deposit.errors.full_messages.join(', ')}"
        end
      end
    end
  end

  def sync_governance_proposal_votes(hubble_proposal)
    votes = get_proposal_votes(hubble_proposal.chain_proposal_id)
    return if votes.nil?

    votes.each do |vote_data|
      address = vote_data['voter']
      option = vote_data['option']
      account = @chain.accounts.find_or_create_by( address: address )

      vote = Cosmos::Governance::Vote.find_or_create_by(
        account: account,
        proposal: hubble_proposal,
        option: option
      ) do |v|
        puts "Vote by #{account.address} recorded against proposal #{hubble_proposal.title}"
      end

      if !vote.valid? || !vote.persisted?
        puts "Invalid vote #{vote_data.inspect} for proposal #{hubble_proposal.title} -- #{vote.errors.full_messages.join(', ')}"
      end
    end
  end

  private

  def build_proposal(proposal)
    # {
    #   "proposal_id":"1",
    #   "title":"First 9002 Proposal",
    #   "description":"I propose nothing",
    #   "proposal_type":"Text",
    #   "proposal_status":"VotingPeriod",
    #   "tally_result":{
    #      "yes":"0.0000000000",
    #      "abstain":"0.0000000000",
    #      "no":"0.0000000000",
    #      "no_with_veto":"0.0000000000"
    #   },
    #   "submit_time":"2018-11-30T18:28:31.925129596Z",
    #   "deposit_end_time":"2018-12-02T18:28:31.925129596Z",
    #   "total_deposit":[
    #      {
    #         "denom":"STAKE",
    #         "amount":"10"
    #      }
    #   ],
    #   "voting_start_time":"2018-11-30T18:28:31.925129596Z",
    #   "voting_end_time":"2018-12-02T18:28:31.925129596Z"
    # }

    {
      chain_proposal_id: proposal['proposal_id'],
      proposal_type: proposal['proposal_type'],
      proposal_status: proposal['proposal_status'],
      title: proposal['title'],
      description: proposal['description'],
      submit_time: DateTime.parse(proposal['submit_time']),
      voting_start_time: DateTime.parse(proposal['voting_start_time']),
      voting_end_time: DateTime.parse(proposal['voting_end_time']),
      total_deposit: proposal['total_deposit']
    }.stringify_keys
  end
end
