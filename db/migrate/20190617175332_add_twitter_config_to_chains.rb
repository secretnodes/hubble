class AddTwitterConfigToChains < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_chains, :twitter_events_config, :jsonb, default: {}
    add_column :terra_chains, :twitter_events_config, :jsonb, default: {}
    add_column :iris_chains, :twitter_events_config, :jsonb, default: {}
  end
end
