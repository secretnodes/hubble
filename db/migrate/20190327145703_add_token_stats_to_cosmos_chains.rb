class AddTokenStatsToCosmosChains < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_chains, :staking_pool, :jsonb, default: {}
  end
end
