class AddCutoffToChains < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_chains, :cutoff_at, :datetime
    add_column :terra_chains, :cutoff_at, :datetime
    add_column :iris_chains, :cutoff_at, :datetime
  end
end
