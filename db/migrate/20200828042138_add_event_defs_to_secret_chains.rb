class AddEventDefsToSecretChains < ActiveRecord::Migration[5.2]
  def change
    add_column :secret_chains, :event_defs, :jsonb
  end
end
