class Cosmos::Governance::Vote < ApplicationRecord
  belongs_to :account, class_name: 'Cosmos::Account'
  belongs_to :proposal, class_name: 'Cosmos::Governance::Proposal'

  validates :option, allow_blank: false, presence: true
end
