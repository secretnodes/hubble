class AddProposerAddressToCosmosBlocks < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_blocks, :proposer_address, :string
  end
end
