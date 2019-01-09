class CreateCosmosGovernanceVotes < ActiveRecord::Migration[5.2]
  def change
    create_table :cosmos_governance_votes do |t|
      t.bigint :account_id
      t.index ["account_id"], name: "index_cosmos_vote_on_account"

      t.bigint :proposal_id
      t.index ["proposal_id"], name: "index_cosmos_vote_on_proposal"

      t.string :option

      t.timestamps
    end
  end
end
