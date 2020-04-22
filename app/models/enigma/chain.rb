class Enigma::Chain < ApplicationRecord
  include Chainlike

  SYNC_OFFSET = 1
  SUPPORTS_LEDGER = true

  PREFIXES = {
    account_address: 'enigma1',
    account_public_key: 'enigmapub1',
    validator_consensus_address: 'enigmavalcons1',
    validator_consensus_public_key: 'enigmavalconspub1',
    validator_operator_address: 'enigmavaloper1',
    validator_operator_public_key: 'enigmavaloperpub1'
  }

  DEFAULT_TOKEN_DISPLAY = 'ATOM'
  DEFAULT_TOKEN_REMOTE = 'uatom'
  DEFAULT_TOKEN_FACTOR = 6

  def network_name; 'enigma'; end
end