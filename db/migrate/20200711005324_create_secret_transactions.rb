class CreateSecretTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :secret_transactions do |t|
      t.bigint :chain_id
      t.bigint :block_id
      t.integer :proposal_id
      t.bigint :height
      t.integer :transaction_type
      t.float :gas_wanted
      t.float :gas_used
      t.float :fee
      t.datetime :timestamp
      t.jsonb :message
      t.jsonb :signature
      t.jsonb :raw_transaction
      t.jsonb :logs
      t.string :hash_id
      t.string :memo
      t.string :error_message

      t.timestamps
    end
  end
end
