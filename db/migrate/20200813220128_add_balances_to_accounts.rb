class AddBalancesToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :secret_accounts, :total_balance, :bigint, default: 0
    add_column :secret_accounts, :available_balance, :bigint, default: 0
    add_column :secret_accounts, :delegated_balance, :bigint, default: 0
    add_column :secret_accounts, :rewards_balance, :bigint, default: 0
    add_column :secret_accounts, :unbonding_balance, :bigint, default: 0
    add_column :secret_accounts, :commission_balance, :bigint, default: 0
  end
end
