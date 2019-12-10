class AddCommunityPoolToChains < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_chains, :community_pool, :json, default: nil
    add_column :terra_chains, :community_pool, :json, default: nil
    add_column :iris_chains, :community_pool, :json, default: nil
    add_column :kava_chains, :community_pool, :json, default: nil
  end
end
