class AddTotalSupplyToSecretChains < ActiveRecord::Migration[5.2]
  def change
    add_column :secret_chains, :total_supply, :bigint
  end
end
