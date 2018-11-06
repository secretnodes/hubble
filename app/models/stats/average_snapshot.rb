class Stats::AverageSnapshot < ApplicationRecord
  belongs_to :chain, class_name: 'Cosmos::Chain'
  belongs_to :scopeable, polymorphic: true, required: false

  default_scope { order('timestamp DESC') }

  def average
    count > 0 ? sum / count : 0
  end
end
