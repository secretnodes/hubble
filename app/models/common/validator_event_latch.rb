class Common::ValidatorEventLatch < ApplicationRecord
  belongs_to :chainlike, polymorphic: true
  belongs_to :validatorlike, polymorphic: true

  validates :event_definition_id, presence: true
end
