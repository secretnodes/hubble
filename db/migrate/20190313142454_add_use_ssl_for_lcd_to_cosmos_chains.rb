class AddUseSslForLcdToCosmosChains < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_chains, :use_ssl_for_lcd, :boolean, default: true
  end
end
