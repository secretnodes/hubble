class AddLastBalanceSyncToSecretChain < ActiveRecord::Migration[5.2]
  def change
    add_column :secret_chains, :last_balance_sync, :datetime
  end
end
