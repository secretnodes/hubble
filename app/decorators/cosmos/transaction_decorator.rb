class Cosmos::TransactionDecorator
  include FormattingHelper

  def initialize( chain, transaction_hash )
    # TODO: cache!
    @chain = chain
    @object = chain.syncer.get_transaction(transaction_hash)
    raise RuntimeError.new("Could not retrieve transaction: #{transaction_hash}") if @object.nil?
  end

  def to_param; hash; end

  def hash
    @object['hash']
  end

  def dump
    @object.as_json
  end

  def fees_raw
    @object['tx']['value']['fee']['amount'].inject(0) { |acc, fee| acc + fee['amount'].to_i }
  end

  def gas_raw
    @object['tx']['value']['fee']['gas'].to_i
  end

  def fees
    @object['tx']['value']['fee']['amount'].map do |fee|
      next if fee['denom'].blank?
      format_amount( fee['amount'].to_i, @chain, token_denom_override: fee['denom'] )
    end.compact
  end

  def gas
    format_amount( gas_raw, @chain, token_denom_override: 'gas' )
  end

  def error?
    code = @object['result']['code']
    !code.nil? && code != 0
  end

  def error_message
    case @object['result']['code']
      when 1 then "Internal Error"
      when 2 then "Transaction Parse Error"
      when 3 then "Invalid Sequence"
      when 4 then "Unauthorized"
      when 5 then "Insufficient Funds"
      when 6 then "Unknown Request"
      when 7 then "Invalid Address"
      when 8 then "Invalid Public Key"
      when 9 then "Unknown Address"
      when 10 then "Insufficient Coins"
      when 11 then "Invalid Coins"
      when 12 then "Out of Gas"
      when 13 then "Memo Too Large"
      when 14 then "Insufficient Fee"
      when 15 then "Too Many Signatures"
      else "Unknown Error"
    end
  end

  def type
    @object['tx']['type']
  end

  def tags
    (@object['result']['tags']||[]).map { |tag| Cosmos::TransactionTagDecorator.new( tag, @chain ) }
  end

  def messages
    (@object['tx']['value']['msg']||[]).map { |msg| Cosmos::TransactionMessageDecorator.new( msg, @chain ) }
  end

  def gas_wanted
    if @object['result'].has_key?('gas_wanted')
      format_amount( @object['result']['gas_wanted'].to_i, @chain, token_denom_override: 'gas' )
    else
      '&mdash;'.html_safe
    end
  end

  def gas_used
    format_amount( @object['result']['gas_used'].to_i, @chain, token_denom_override: 'gas' )
  end

  def log
    @object['result']['log']
  end

  def memo
    @object['tx']['value']['memo']
  end

  def signatures
    @object['tx']['value']['signatures']
  end
end
