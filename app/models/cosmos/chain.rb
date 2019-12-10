class Cosmos::Chain < ApplicationRecord
  include Chainlike

  SYNC_OFFSET = 1
  SUPPORTS_LEDGER = true

  PREFIXES = {
    account_address: 'cosmos1',
    account_public_key: 'cosmospub1',
    validator_consensus_address: 'cosmosvalcons1',
    validator_consensus_public_key: 'cosmosvalconspub1',
    validator_operator_address: 'cosmosvaloper1',
    validator_operator_public_key: 'cosmosvaloperpub1'
  }

  DEFAULT_TOKEN_DISPLAY = 'ATOM'
  DEFAULT_TOKEN_REMOTE = 'uatom'
  DEFAULT_TOKEN_FACTOR = 6

  def network_name; 'Cosmos'; end
end
