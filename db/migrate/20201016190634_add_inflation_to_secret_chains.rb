class AddInflationToSecretChains < ActiveRecord::Migration[6.0]
  def change
    add_column :secret_chains, :inflation, :float, default: 0.0
  end
end
