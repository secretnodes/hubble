module FaucetHelper

  def sorted_faucet_token_denominations( chain, tokens )
    tokens.keys.sort { |denom| denom == 'stake' ? -1 : 1 }
  end

end
