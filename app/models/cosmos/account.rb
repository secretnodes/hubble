class Cosmos::Account < ApplicationRecord
  belongs_to :chain, class_name: 'Cosmos::Chain'
  belongs_to :validator, class_name: 'Cosmos::Validator', optional: true

  has_many :governance_deposits, class_name: 'Cosmos::Governance::Deposit'
  has_many :governance_votes, class_name: 'Cosmos::Governance::Vote'

  validates :address, allow_blank: false, presence: true, uniqueness: { scope: :chain }
end
