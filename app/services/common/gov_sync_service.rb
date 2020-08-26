class Common::GovSyncService
  def initialize( chain )
    @chain = chain
    @syncer = @chain.syncer( 10_000 )
  end

  def sync_params!
    ProgressReport.instance.start "Syncing Governance Params for #{@chain.network_name}/#{@chain.name}..."

    return if @chain.governance_params_synced?
    @chain.update_attributes governance: (@syncer.get_governance||{})

    ProgressReport.instance.report
  end

  def sync_pool!
    ProgressReport.instance.start "Syncing Community Pool for #{@chain.network_name}/#{@chain.name}..."

    pool = @syncer.get_community_pool
    if pool && pool.is_a?(Array)
      pool.map do |balance|
        balance['amount'] = balance['amount'].to_f
        balance
      end
    end
    @chain.update_attributes community_pool: pool

    ProgressReport.instance.report
  end

  def sync_token_stats!
    ProgressReport.instance.start "Syncing Token Stats for #{@chain.network_name}/#{@chain.name}..."

    staking_pool = @syncer.get_staking_pool
    @chain.update_attributes staking_pool: staking_pool

    ProgressReport.instance.report
  end

  def sync_proposals!
    return if !@chain.governance_params_synced?

    ProgressReport.instance.start "Syncing Governance Proposals for #{@chain.network_name}/#{@chain.name}..."

    tracked_proposal_ids = []

    @syncer.get_proposals.try(:each) do |proposal|
      # TODO update enigma gov_sync_service#build_proposal for '0.38.0' sdk version
      proposal_details = build_proposal(proposal)
      next if proposal_details.nil?

      tracked_proposal_ids << proposal_details['ext_id']

      begin
        working_proposal = @chain.governance_proposals.find_by(
          ext_id: proposal_details['ext_id']
        )

        if working_proposal
          if working_proposal.finalized? && working_proposal.proposal_status != 'VotingPeriod'
            puts "Skipping finalized proposal: #{working_proposal.ext_id} - #{working_proposal.title}"
          else
            puts "Updating existing proposal: #{working_proposal.ext_id} - #{working_proposal.title}"
            working_proposal.update_attributes(proposal_details)
          end
        else
          working_proposal = @chain.governance_proposals.create(proposal_details)
          puts "Synced new proposal: #{working_proposal.ext_id} - #{working_proposal.title}"
        end

        sync_governance_proposal_deposits(working_proposal)
        sync_governance_proposal_votes(working_proposal)
        sync_governance_proposal_tallies(working_proposal)

        if working_proposal.ended?
          working_proposal.update_attributes( finalized: true )
          puts "Finalized past proposal: #{working_proposal.ext_id} - #{working_proposal.title}"
        end
      end
    end

    # to_purge = @chain.governance_proposals.where.not( ext_id: tracked_proposal_ids )
    # if to_purge.any?
    #   puts "Purging old dead proposals: #{to_purge.map(&:ext_id)}"
    #   to_purge.map(&:destroy)
    # end

    ProgressReport.instance.report
  end

  private

  def sync_governance_proposal_tallies(puzzle_proposal)
    tally = @syncer.get_proposal_tally(puzzle_proposal.ext_id)
    return if tally.nil?

    puzzle_proposal.update_attributes(
      tally_result_yes: tally['yes'],
      tally_result_no: tally['no'],
      tally_result_abstain: tally['abstain'],
      tally_result_nowithveto: tally['no_with_veto']
    )
  end

  def sync_governance_proposal_deposits(puzzle_proposal)
    deposits = @syncer.get_proposal_deposits( puzzle_proposal.ext_id )
    return if deposits.nil?

    by_depositor = deposits.group_by { |dep| dep['depositer'] || dep['depositor'] }

    by_depositor.entries.each do |address, deposits|
      deposit = deposits.last
      account = @chain.accounts.find_or_create_by!( address: address )

      deposit['amount'].try(:each) do |deposit_amount|
        amount_denom = deposit_amount['denom']
        amount = deposit_amount['amount'].to_i

        deposit = @chain.namespace::Governance::Deposit.find_by(
          account: account,
          proposal: puzzle_proposal
        )

        if deposit
          # ensure only 1 deposit for this account/proposal pair
          extras = @chain.namespace::Governance::Deposit
            .where( account: account, proposal: puzzle_proposal )
            .where( 'id != ?', deposit.id )
          if extras.any?
            puts "Purging #{extras.count} extra deposits for #{account.address} (#{account.address}/#{puzzle_proposal.id})..."
            extras.map(&:destroy)
          end

          deposit.assign_attributes( amount_denom: amount_denom, amount: amount )
          if deposit.changed?
            puts "Deposit by #{account.address} on #{puzzle_proposal.title} updated (#{deposit.changes})"
            deposit.save
          end
        else
          deposit = @chain.namespace::Governance::Deposit.create(
            account: account,
            proposal: puzzle_proposal,
            amount_denom: amount_denom,
            amount: amount
          )
          puts "Deposit by #{account.address} recorded against #{puzzle_proposal.title}"
        end

        if !deposit.valid? || !deposit.persisted?
          puts "Invalid deposit #{deposit_amount.inspect} for proposal #{puzzle_proposal.title} -- #{deposit.errors.full_messages.join(', ')}"
        end
      end
    end
  end

  def sync_governance_proposal_votes(puzzle_proposal)
    votes = @syncer.get_proposal_votes(puzzle_proposal.ext_id)
    return if !votes.present?

    by_voter = votes.group_by { |vote| vote['voter'] }

    by_voter.entries.each do |address, votes|
      vote_data = votes.last
      option = vote_data['option']
      account = @chain.accounts.find_or_create_by!( address: address )

      vote = @chain.namespace::Governance::Vote.find_by( account: account, proposal: puzzle_proposal )

      if vote
        # ensure only 1 vote for this account/proposal pair
        extras = @chain.namespace::Governance::Vote
          .where( account: account, proposal: puzzle_proposal )
          .where( 'id != ?', vote.id )
        if extras.any?
          puts "Purging #{extras.count} extra votes for #{account.address} (#{account.address}/#{puzzle_proposal.id})..."
          extras.map(&:destroy)
        end

        vote.assign_attributes( option: option )
        if vote.changed?
          puts "Vote by #{account.address} on #{puzzle_proposal.title} updated (#{vote.changes})"
          vote.save
        end
      else
        vote = @chain.namespace::Governance::Vote.create(
          account: account,
          proposal: puzzle_proposal,
          option: option
        )
        puts "Vote (#{option}) by #{account.address} recorded against proposal #{puzzle_proposal.title}"
      end

      if !vote.valid? || !vote.persisted?
        puts "Invalid vote #{vote_data.inspect} for proposal #{puzzle_proposal.title} -- #{vote.errors.full_messages.join(', ')}"
      end
    end
  end

  private

  def build_proposal( proposal )
    raise NotImplementedError.new("Implement #build_proposal for #{self.class.name}")
  end
end
