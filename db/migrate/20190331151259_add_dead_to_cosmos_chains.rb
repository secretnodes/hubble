class AddDeadToCosmosChains < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_chains, :dead, :boolean, default: false
  end
end
