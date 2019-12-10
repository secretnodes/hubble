class AddLastUpdatedToCosmosValidators < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_validators, :last_updated, :datetime
  end
end
