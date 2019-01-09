class Cosmos::Governance::Proposal < ApplicationRecord
  belongs_to :chain, class_name: 'Cosmos::Chain'
  has_many :deposits, class_name: 'Cosmos::Governance::Deposit', dependent: :delete_all
  has_many :votes, class_name: 'Cosmos::Governance::Vote', dependent: :delete_all

  scope :ordered_by_submit_time, -> { order( submit_time: :desc ) }
  scope :voting_open, -> { where( 'voting_end_time > ?', Time.now ) }

  def to_param; chain_proposal_id.to_s; end

  def total_deposits
    denoms = total_deposit.map { |td| td['denom'] }.uniq

    denoms.each do |denom|
      total_amount_for_denom = total_deposit
        .select { |d| d['denom'] == denom }
        .inject(0) { |acc, td| acc + td['amount'].to_i }
      { denom: denom, total_amount: total_amount_for_denom }
    end
  end

  def status_string
    case proposal_status.downcase
    when 'depositperiod' then 'Deposit Period'
    when 'votingperiod' then 'Voting Period'
    else proposal_status
    end
  end

  def in_deposit_period?
    proposal_status.downcase == 'depositperiod'
  end

  def cumulative_voting_power
    (tally_result_yes||0) + (tally_result_abstain||0) +
    (tally_result_no||0) + (tally_result_nowithveto||0)
  end

  def missing_vote_data?
    voting_end_time.past? && votes.count.zero? && cumulative_voting_power > 0
  end

  def missing_deposits_data?
    voting_end_time.past? && deposits.count.zero? && cumulative_voting_power > 0
  end
end
