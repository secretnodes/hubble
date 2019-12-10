class PromoteOwnerOnCosmosValidators < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_validators, :owner, :string
  end
end
