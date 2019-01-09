class Cosmos::Governance::Deposit < ApplicationRecord
  belongs_to :account, class_name: 'Cosmos::Account'
  belongs_to :proposal, class_name: 'Cosmos::Governance::Proposal'
end
