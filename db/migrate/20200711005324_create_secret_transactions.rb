class CreateSecretTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :secret_transactions do |t|
      t.integer :chain_id
      t.integer :block_id
      t.integer :chain_id
      t.integer :transaction_type
      t.jsonb :raw_transaction
      t.float :gas_wanted
      t.float :gas_used
      t.float :fee
      t.datetime :timestamp
      t.jsonb :message
      t.string :signature

      t.timestamps
    end
  end
end
