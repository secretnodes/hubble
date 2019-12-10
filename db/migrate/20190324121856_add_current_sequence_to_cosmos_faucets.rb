class AddCurrentSequenceToCosmosFaucets < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_faucets, :current_sequence, :string
  end
end
