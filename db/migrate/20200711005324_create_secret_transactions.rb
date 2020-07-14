class CreateSecretTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :secret_transactions do |t|
      t.integer :chain_id
      t.integer :block_id
      t.integer :proposal_id
      t.bigint :height
      t.integer :transaction_type
      t.jsonb :raw_transaction
      t.float :gas_wanted
      t.float :gas_used
      t.float :fee
      t.datetime :timestamp
      t.jsonb :message
      t.jsonb :signature
      t.string :hash_id

      t.timestamps
    end
  end
end
