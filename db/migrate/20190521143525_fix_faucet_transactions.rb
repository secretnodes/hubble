class FixFaucetTransactions < ActiveRecord::Migration[5.2]
  def change
    rename_column :stats_faucet_transactions, :faucet_id, :faucetlike_id
    add_column :stats_faucet_transactions, :faucetlike_type, :string
    Stats::FaucetTransaction.update_all( faucetlike_type: 'Cosmos::Faucet' )
  end
end
