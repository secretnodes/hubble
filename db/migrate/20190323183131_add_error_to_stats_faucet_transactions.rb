class AddErrorToStatsFaucetTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :stats_faucet_transactions, :error, :boolean
  end
end
