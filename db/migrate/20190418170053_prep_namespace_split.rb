class PrepNamespaceSplit < ActiveRecord::Migration[5.2]
  def change
    rename_column :cosmos_governance_proposals, :chain_proposal_id, :ext_id
    remove_column :cosmos_governance_proposals, :cosmos_chain_id

    rename_column :stats_daily_sync_logs, :chain_id, :chainlike_id
    add_column :stats_daily_sync_logs, :chainlike_type, :string
    Stats::DailySyncLog.update_all( chainlike_type: 'Cosmos::Chain' )

    rename_column :stats_sync_logs, :chain_id, :chainlike_id
    add_column :stats_sync_logs, :chainlike_type, :string
    Stats::SyncLog.update_all( chainlike_type: 'Cosmos::Chain' )

    rename_table :cosmos_validator_event_latches, :common_validator_event_latches
    rename_column :common_validator_event_latches, :chain_id, :chainlike_id
    add_column :common_validator_event_latches, :chainlike_type, :string
    rename_column :common_validator_event_latches, :validator_id, :validatorlike_id
    add_column :common_validator_event_latches, :validatorlike_type, :string
    Common::ValidatorEventLatch.update_all( chainlike_type: 'Cosmos::Chain', validatorlike_type: 'Cosmos::Validator' )

    rename_table :cosmos_validator_events, :common_validator_events
    rename_column :common_validator_events, :chain_id, :chainlike_id
    add_column :common_validator_events, :chainlike_type, :string
    rename_column :common_validator_events, :validator_id, :validatorlike_id
    add_column :common_validator_events, :validatorlike_type, :string
    Common::ValidatorEvent.update_all( chainlike_type: 'Cosmos::Chain', validatorlike_type: 'Cosmos::Validator' )
    Common::ValidatorEvent.update_all( "type = replace(type, 'Cosmos::', 'Common::')" )

    rename_table :cosmos_watches, :common_watches
    rename_column :common_watches, :chain_id, :chainlike_id
    add_column :common_watches, :chainlike_type, :string
    Common::Watch.update_all( chainlike_type: 'Cosmos::Chain' )
  end
end
