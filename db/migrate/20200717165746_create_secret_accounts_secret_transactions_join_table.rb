class CreateSecretAccountsSecretTransactionsJoinTable < ActiveRecord::Migration[5.2]
  def change
    create_join_table :accounts, :transactions, table_name: :secret_accounts_secret_transactions do |t|
      t.index [:account_id, :transaction_id], name: :index_secret_accounts_transactions
      # t.index [:secret_account_id, :secret_transaction_id]
      # t.index [:secret_transaction_id, :secret_account_id]
    end
  end
end
