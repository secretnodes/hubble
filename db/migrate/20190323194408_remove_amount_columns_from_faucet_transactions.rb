class RemoveAmountColumnsFromFaucetTransactions < ActiveRecord::Migration[5.2]
  def change
    remove_column :stats_faucet_transactions, :amount
    remove_column :stats_faucet_transactions, :denom
  end
end
