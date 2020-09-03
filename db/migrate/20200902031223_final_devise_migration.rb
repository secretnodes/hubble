class FinalDeviseMigration < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :encrypted_password
    rename_column :users, :password_digest, :encrypted_password
  end
end
