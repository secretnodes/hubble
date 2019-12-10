class AddDepositEndTimeToCosmosGovernanceProposals < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_governance_proposals, :deposit_end_time, :datetime
  end
end
