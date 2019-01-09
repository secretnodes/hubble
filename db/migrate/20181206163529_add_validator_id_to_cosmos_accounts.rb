class AddValidatorIdToCosmosAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_accounts, :validator_id, :bigint, null: true
  end
end
