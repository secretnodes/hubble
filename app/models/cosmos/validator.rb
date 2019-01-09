class Cosmos::Validator < ApplicationRecord
  belongs_to :chain, class_name: 'Cosmos::Chain'
  has_many :events, class_name: 'Cosmos::ValidatorEvent'
  has_many :latches, class_name: 'Cosmos::ValidatorEventLatch'
  has_many :alert_subscriptions, as: :alertable

  has_one :account, class_name: 'Cosmos::Account'

  validates :address, presence: true, allow_blank: false, uniqueness: { scope: :chain }

  def to_param; address; end

  class << self
    def total_voting_power( chain )
      sum(:current_voting_power)
    end
  end

  def has_info?
    (info||{}).any?
  end

  def short_name( max_length=16 )
    moniker ||
    owner ||
    address.truncate( max_length, separator: '...' )
  end

  def long_name
    moniker || owner || address
  end

  def owner
    info_field( 'owner' ) || info_field( 'operator_address' )
  end

  def moniker
    info_field( 'description', 'moniker' ) || nil
  end

  def proposals
    return [] unless account
    ids = [
      *account.governance_deposits.select('DISTINCT proposal_id'),
      *account.governance_votes.select('DISTINCT proposal_id')
    ].map(&:proposal_id).uniq
    chain.governance_proposals.where( id: ids )
  end

  def recent_events( type, since )
    events.where( type: type.to_s ).where( 'timestamp >= ?', since )
  end

  def in_active_set?( block=nil )
    if block.nil?
      block = chain.blocks.first
    end
    block.validator_set.keys.include?( address )
  end

  def voting_power_history
    events.where( type: 'Cosmos::ValidatorEvents::VotingPowerChange' )
  end
  def active_set_history
    events.where( type: 'Cosmos::ValidatorEvents::ActiveSetInclusion' )
  end

  def info_field( *fields )
    begin
      current = info
      fields.each do |f|
        current = current[f.to_s]
      end
      current.blank? ? nil : current
    rescue
      nil
    end
  end

  def voting_power_at_height( height )
    block = chain.blocks.find_by( height: height ) || Cosmos::Block.stub_from_cache( chain, height )
    block.validator_set[self.address]
  end

  def last_updated
    entry = voting_power_history.first
    return nil if entry.nil?

    chain.blocks.find_by( height: entry.height ).timestamp
  end

  def last_precommitted_block
    # this is too damn slow
    # chain.blocks.where( 'precommitters @> ARRAY[?]::varchar[]', address ).first

    return nil if latest_block_height.nil? || latest_block_height.zero?
    chain.blocks.find_by( height: latest_block_height ) ||
    Cosmos::Block.stub( chain, latest_block_height )
  end

  def proposal_probability
    total = chain.validators.sum(:current_voting_power)
    return 0 if total.zero?
    current_voting_power / total.to_f
  end

  def active?
    (current_voting_power||0) > 0
  end

  def calculate_current_uptime( blocks_num: 100 )
    blocks = chain.blocks.limit( blocks_num )
    num_blocks = blocks.count
    return 0.0 if num_blocks.zero?

    precommits = blocks
      .select { |b| b.precommitters.include?(address) }
      .count

    (precommits / blocks.count.to_f).round(2)
  end
end
