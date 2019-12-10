class CreateCosmosGovernanceDeposits < ActiveRecord::Migration[5.2]
  def change
    create_table :cosmos_governance_deposits do |t|

      t.bigint :account_id
      t.index ["account_id"], name: "index_cosmos_deposit_on_account"
      
      t.bigint :proposal_id
      t.index ["proposal_id"], name: "index_cosmos_deposit_on_proposal"

      t.string :amount_denom
      t.bigint :amount

      t.timestamps
    end
  end
end
