class Cosmos::Chain < ApplicationRecord
  has_many :blocks, class_name: 'Cosmos::Block', dependent: :delete_all
  has_many :validators, class_name: 'Cosmos::Validator', dependent: :delete_all

  has_many :events, class_name: 'Cosmos::ValidatorEvent', dependent: :delete_all
  has_many :latches, class_name: 'Cosmos::ValidatorEventLatch', dependent: :delete_all

  has_many :average_snapshots, class_name: 'Stats::AverageSnapshot', dependent: :delete_all
  has_many :sync_logs, class_name: 'Stats::SyncLog', dependent: :delete_all
  has_many :daily_sync_logs, class_name: 'Stats::DailySyncLog', dependent: :delete_all

  has_many :accounts, class_name: 'Cosmos::Account', dependent: :delete_all
  has_many :governance_proposals, class_name: 'Cosmos::Governance::Proposal', dependent: :delete_all

  has_one :faucet, class_name: 'Cosmos::Faucet', dependent: :destroy

  validates :name, presence: true, allow_blank: false
  validates :slug, presence: true, uniqueness: true, format: { with: /[a-z0-9-]+/ }, allow_blank: false

  def to_param; slug; end
  def network_name; 'Cosmos'; end
  def enabled?; !disabled?; end

  scope :enabled, -> { where( disabled: false ) }
  scope :primary, -> {
    find_by( primary: true ) || order('created_at DESC').first
  }

  def get_event_height( defn_id )
    defn = self.validator_event_defs.find { |defn| defn['unique_id'] == defn_id }
    defn ? (defn['height'] || 0) : 0
  end

  def set_event_height!( defn_id, height )
    self.validator_event_defs_will_change!
    defn = self.validator_event_defs.find { |defn| defn['unique_id'] == defn_id }
    defn['height'] = height
    self.save!
  end

  def syncer
    @_syncer ||= Cosmos::SyncBase.new( self, 500 )
  end

  def can_communicate_with_node?
    return false if self.ext_id.blank?
    begin
      # ensure lcd and rpc are available
      syncer.get_stake_info
      syncer.get_node_chain == self.ext_id
    rescue
      Rails.logger.error $!.message
      nil
    end
  end

  def get_gaiad_host_or_default
    gaiad_host.blank? ?
      Rails.application.secrets.default_gaiad_host :
      gaiad_host
  end

  def get_rpc_port_or_default
    rpc_port.blank? ?
      Rails.application.secrets.default_rpc_port :
      rpc_port
  end

  def get_lcd_port_or_default
    lcd_port.blank? ?
      Rails.application.secrets.default_lcd_port :
      lcd_port
  end

  def latest_local_height
    blocks.first.try(:height) || 0
  end

  def active_validators_at_height( height )
    block = blocks.find_by( height: height ) || Cosmos::Block.stub( self, height )
    validators.where( address: block.validator_set.keys )
  rescue
    []
  end

  def average_block_time( last_n_blocks: 100 )
    times = []
    lastest_blocks = blocks.limit( last_n_blocks ).to_a

    latest_time = lastest_blocks.shift.timestamp

    # include now, so that network being down results in
    # slowly creeping average block time?
    # times << Time.now.utc - latest_time

    lastest_blocks.each do |block|
      times << latest_time - block.timestamp
      latest_time = block.timestamp
    end

    times.reduce(:+) / times.count
  end

  def total_current_voting_power
    validators.total_voting_power( self )
  end

  def voting_power_online
    online = validators.where( address: blocks.first.precommitters )
    online.sum { |v| v.current_voting_power || 0 }
  end

  def failing_sync?
    failed_sync_count > 0
  end

  def sync_failed!
    increment! :failed_sync_count
  end

  def sync_completed!
    update_attributes failed_sync_count: 0
  end

  def governance_params_synced?
    governance != {}
  end

  def governance_params
    @governance_params ||= Cosmos::GovernanceParamsDecorator.new(governance)
  end

  def progressing!
    update_attributes halted_at: nil
  end

  def has_halted!
    update_attributes halted_at: DateTime.now
  end

  def halted?
    !halted_at.nil?
  end

  def record_round_state( round_state )
    update_attributes last_round_state: round_state
  end
end
