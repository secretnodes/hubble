class AddPositionToChains < ActiveRecord::Migration[5.2]
  def change
    add_column :cosmos_chains, :position, :integer
    Cosmos::Chain.order(:updated_at).each.with_index(1) do |chain, index|
      chain.update_column :position, index
    end

    add_column :terra_chains, :position, :integer
    Cosmos::Chain.order(:updated_at).each.with_index(1) do |chain, index|
      chain.update_column :position, index
    end
  end
end
