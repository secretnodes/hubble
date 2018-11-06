class Cosmos::ValidatorEventLatch < ApplicationRecord
  belongs_to :chain, class_name: 'Cosmos::Chain'
  belongs_to :validator, class_name: 'Cosmos::Validator'
end
