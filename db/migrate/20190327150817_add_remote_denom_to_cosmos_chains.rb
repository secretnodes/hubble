class AddRemoteDenomToCosmosChains < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_chains, :remote_denom, :string
  end
end
