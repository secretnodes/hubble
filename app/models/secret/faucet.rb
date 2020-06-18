class Secret::Faucet < ApplicationRecord
  include Faucetlike

  def broadcast_tx( final_tx )
    payload = { tx: final_tx, mode: 'sync' }
    result = chain.syncer(8000).broadcast_tx( payload )
    Rails.logger.error "\n\nBROADCAST RESULT: #{result.inspect}\n\n"
    ok = !result.has_key?('code') && !result.has_key?('error')

    next_sequence = (self.current_sequence.to_i + 1).to_s
    update_attributes(current_sequence: next_sequence) if ok

    [ok, result]
  end
end
