class AdjustCosmosFaucets < ActiveRecord::Migration[5.2]
  def change
    remove_column :cosmos_faucets, :key_name, :string
    remove_column :cosmos_faucets, :delay, :integer
    remove_column :cosmos_faucets, :tokens, :jsonb
    remove_column :cosmos_faucets, :account_number, :string
    remove_column :cosmos_faucets, :current_sequence, :string
    rename_column :cosmos_faucets, :encrypted_password, :encrypted_private_key
    rename_column :cosmos_faucets, :encrypted_password_iv, :encrypted_private_key_iv
    add_column :cosmos_faucets, :disbursement_amount, :string
    add_column :cosmos_faucets, :fee_amount, :string
    add_column :cosmos_faucets, :denom, :string

    add_column :stats_faucet_transactions, :txhash, :string
    rename_column :stats_faucet_transactions, :denomination, :denom
    change_column :stats_faucet_transactions, :amount, :string
  end
end
