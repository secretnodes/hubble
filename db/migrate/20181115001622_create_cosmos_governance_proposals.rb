class CreateCosmosGovernanceProposals < ActiveRecord::Migration[5.2]
  def change
    create_table :cosmos_governance_proposals do |t|
      t.bigint :chain_id
      t.bigint :chain_proposal_id
      t.string :title
      t.text :description
      t.string :proposal_type
      t.string :proposal_status
      t.decimal :tally_result_yes
      t.decimal :tally_result_abstain
      t.decimal :tally_result_no
      t.decimal :tally_result_nowithveto
      t.datetime :submit_time
      t.jsonb :total_deposit, default: {}
      t.datetime :voting_start_time
      t.datetime :voting_end_time
      t.references :cosmos_chain, foreign_key: true
      t.index ["chain_id"], name: "index_cosmos_proposal_on_chain"

      t.timestamps
    end
    add_index :cosmos_governance_proposals, :chain_proposal_id
    add_index :cosmos_governance_proposals, :proposal_type
    add_index :cosmos_governance_proposals, :proposal_status
    add_index :cosmos_governance_proposals, :submit_time
    add_index :cosmos_governance_proposals, :voting_start_time
    add_index :cosmos_governance_proposals, :voting_end_time
    add_index :cosmos_governance_proposals, [:chain_id, :chain_proposal_id], unique: true, name: "index_cosmos_governance_proposals_on_chain_and_cp_id"
  end
end
