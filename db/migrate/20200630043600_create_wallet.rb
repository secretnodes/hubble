class CreateWallet < ActiveRecord::Migration[5.2]
  def change
    create_table :wallets do |t|
      t.string :public_address
      t.integer :chain_id
      t.string :chain_type
      t.integer :account_index
      t.string :public_key
      t.integer :wallet_type
      t.integer :user_id
    end
  end
end
