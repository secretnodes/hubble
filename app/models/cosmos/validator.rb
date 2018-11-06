class Cosmos::Validator < ApplicationRecord
  belongs_to :chain, class_name: 'Cosmos::Chain'
  has_many :events, class_name: 'Cosmos::ValidatorEvent'
  has_many :latches, class_name: 'Cosmos::ValidatorEventLatch'
  has_many :alert_subscriptions, as: :alertable

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
    info_field( 'owner' )
  end

  def moniker
    info_field( 'description', 'moniker' ) || nil
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
    event = voting_power_history.where( %{ height <= ? }, height ).first
    return 0 if event.nil?
    event.data['to']
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

  def active?
    (current_voting_power||0) > 0
  end

  def uptime( blocks_num: 100 )
    blocks = chain.blocks.limit( blocks_num )

    precommits = blocks
      .select { |b| b.precommitters.include?(address) }
      .count

    # .where( 'precommitters @> ARRAY[?]::varchar[]', address )
    (precommits / 100.0 * 100).round(0)
  end
end
