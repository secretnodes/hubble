class CoinGeckoClient

  def initialize
    @base_uri = "https://api.coingecko.com/api/v3"
  end

  def get_usd_price(coin_id)
    h = {ids: coin_id, vs_currencies: "usd"}.to_param
    url = "#{@base_uri}/simple/price?#{h}"
    r = Typhoeus.get( url )
  end
end