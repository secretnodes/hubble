class Kava::Chain < ApplicationRecord
  include Chainlike

  SYNC_OFFSET = 1
  SUPPORTS_LEDGER = false

  PREFIXES = {
    account_address: 'kava1',
    account_public_key: 'kavapub1',
    validator_consensus_address: 'kavavalcons1',
    validator_consensus_public_key: 'kavavalconspub1',
    validator_operator_address: 'kavavaloper1',
    validator_operator_public_key: 'kavavaloperpub1'
  }

  DEFAULT_TOKEN_DISPLAY = 'KAVA'
  DEFAULT_TOKEN_REMOTE = 'ukava'
  DEFAULT_TOKEN_FACTOR = 6

  def network_name; 'Kava'; end
end
