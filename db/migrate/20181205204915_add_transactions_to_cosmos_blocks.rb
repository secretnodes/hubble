class AddTransactionsToCosmosBlocks < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_blocks, :transactions, :string, array: true
  end
end
