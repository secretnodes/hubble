class AddNotesToCosmosChain < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_chains, :notes, :text
  end
end
