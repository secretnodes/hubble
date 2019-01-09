class CreateCosmosAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :cosmos_accounts do |t|
      t.string :address
      t.bigint :chain_id
      t.index ["chain_id"], name: "index_cosmos_account_on_chain"

      t.timestamps
    end
    add_index :cosmos_accounts, :address
  end
end
