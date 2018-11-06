module FaucetHelper

  def sorted_faucet_token_denominations( chain, tokens )
    tokens.keys.sort { |denom| denom == 'steak' ? -1 : 1 }
  end

end
