class DropHaltedBoolean < ActiveRecord::Migration[5.2]
  def change
    remove_column :cosmos_chains, :halted, :boolean, default: false
  end
end
