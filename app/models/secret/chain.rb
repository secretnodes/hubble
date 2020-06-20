class Secret::Chain < ApplicationRecord
  include Chainlike

  SYNC_OFFSET = 1
  SUPPORTS_LEDGER = true

  PREFIXES = {
    account_address: 'secret1',
    account_public_key: 'secretpub1',
    validator_consensus_address: 'secretvalcons1',
    validator_consensus_public_key: 'secretvalconspub1',
    validator_operator_address: 'secretvaloper1',
    validator_operator_public_key: 'secretvaloperpub1'
  }

  DEFAULT_TOKEN_DISPLAY = 'SCRT'
  DEFAULT_TOKEN_REMOTE = 'uscrt'
  DEFAULT_TOKEN_FACTOR = 6

  def network_name; 'secret'; end
end