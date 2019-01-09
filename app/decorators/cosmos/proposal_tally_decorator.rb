class Cosmos::ProposalTallyDecorator
  include FormattingHelper

  def initialize(proposal)
    @proposal = proposal
  end

  def raw_yes
    @proposal.tally_result_yes
  end

  def raw_abstain
    @proposal.tally_result_abstain
  end

  def raw_no
    @proposal.tally_result_no
  end

  def raw_no_with_veto
    @proposal.tally_result_nowithveto
  end

  def no_votes?
    @proposal.cumulative_voting_power == 0
  end

  def percent_yes
    return 0 if no_votes?
    round_if_whole((raw_yes / (@proposal.cumulative_voting_power)) * 100, 2)
  end

  def percent_no
    return 0 if no_votes?
    round_if_whole((raw_no / (@proposal.cumulative_voting_power)) * 100, 2)
  end

  def percent_abstain
    return 0 if no_votes?
    round_if_whole((raw_abstain / (@proposal.cumulative_voting_power)) * 100, 2)
  end

  def percent_no_with_veto
    return 0 if no_votes?
    round_if_whole((raw_no_with_veto / (@proposal.cumulative_voting_power)) * 100, 2)
  end
end
