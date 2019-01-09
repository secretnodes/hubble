class AddTotalProposalsToCosmosValidators < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_validators, :total_proposals, :bigint, default: 0
  end
end
