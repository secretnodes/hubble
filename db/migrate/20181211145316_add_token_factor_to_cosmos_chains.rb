class AddTokenFactorToCosmosChains < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_chains, :token_denom, :string, default: 'atom'
    add_column :cosmos_chains, :token_factor, :bigint, default: 0
  end
end
