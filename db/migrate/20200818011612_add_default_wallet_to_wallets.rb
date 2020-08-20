class AddDefaultWalletToWallets < ActiveRecord::Migration[5.2]
  def change
    add_column :wallets, :default_wallet, :boolean, default: false
  end
end
