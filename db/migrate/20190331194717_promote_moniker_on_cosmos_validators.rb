class PromoteMonikerOnCosmosValidators < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_validators, :moniker, :string
  end
end
