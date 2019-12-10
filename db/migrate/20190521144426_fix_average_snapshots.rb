class FixAverageSnapshots < ActiveRecord::Migration[5.2]
  def change
    rename_column :stats_average_snapshots, :chain_id, :chainlike_id
    add_column :stats_average_snapshots, :chainlike_type, :string

    Stats::AverageSnapshot
      .where( scopeable_type: 'Iris::Validator' )
      .update_all( chainlike_type: 'Iris::Chain' )

    Stats::AverageSnapshot
      .where( scopeable_type: 'Terra::Validator' )
      .update_all( chainlike_type: 'Terra::Chain' )

    Stats::AverageSnapshot
      .where( scopeable_type: 'Cosmos::Validator' )
      .update_all( chainlike_type: 'Cosmos::Chain' )

    Stats::AverageSnapshot
      .where( scopeable_type: nil )
      .update_all( chainlike_type: 'Cosmos::Chain' )
  end
end
