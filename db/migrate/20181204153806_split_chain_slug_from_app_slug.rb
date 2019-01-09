class SplitChainSlugFromAppSlug < ActiveRecord::Migration[5.2]
  def up
    add_column :cosmos_chains, :ext_id, :string, null: true
  end
end
