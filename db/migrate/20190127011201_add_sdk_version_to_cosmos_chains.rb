class AddSdkVersionToCosmosChains < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_chains, :sdk_version, :string
  end
end
