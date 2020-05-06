class AddFinalizedToEnigmaGovernanceProposals < ActiveRecord::Migration[5.2]
  def change
    add_column :enigma_governance_proposals, :finalized, :boolean, default: false
  end
end
