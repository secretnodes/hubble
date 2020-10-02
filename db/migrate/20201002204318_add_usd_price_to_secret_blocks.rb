class AddUsdPriceToSecretBlocks < ActiveRecord::Migration[5.2]
  def change
    add_column :secret_blocks, :usd_price, :decimal, precision: 8, scale: 2
  end
end
