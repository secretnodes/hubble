module Petitionlike
  extend ActiveSupport::Concern

  included do |klass|
    namespace = klass.name.split('::').first.constantize

    belongs_to :chain, class_name: "#{namespace}::Chain"
    belongs_to :user
    has_many :votes, class_name: "#{namespace}::PetitionVote", dependent: :delete_all

    acts_as_commentable

    scope :ordered_by_submit_time, -> { order( voting_start_time: :desc ) }
    scope :voting_open, -> { where( 'voting_end_time > ?', Time.now ) }
    enum status: [:voting_period, :rejected, :passed]
    enum petition_type: %i{ petition foundation }

    validates_presence_of :title, :description, :voting_end_time, :petition_type
    validates_presence_of :contact_info, if: :foundation?
  end

  def to_param; id.to_s; end

  def ended?
    passed? || rejected? || (voting_end_time.past?)
  end

  def rejected?
    status.downcase == 'rejected'
  end

  def passed?
    status.downcase == 'passed'
  end

  def in_voting_period?
    status.downcase == 'voting_period'
  end

  def cumulative_voting_power
    (tally_result_yes||0) + (tally_result_abstain||0) +
    (tally_result_no||0)
  end

  def missing_vote_data?
    voting_end_time.past? && votes.count.zero? && cumulative_voting_power > 0
  end
end
