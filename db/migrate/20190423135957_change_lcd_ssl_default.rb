class ChangeLcdSslDefault < ActiveRecord::Migration[5.2]
  def change
    change_column_default :cosmos_chains, :use_ssl_for_lcd, false
    change_column_default :terra_chains, :use_ssl_for_lcd, false
  end
end
