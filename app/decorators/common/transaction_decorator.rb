class Common::TransactionDecorator
  include FormattingHelper
  include ActionView::Helpers::DateHelper

  def initialize( chain, transaction, transaction_hash )
    # TODO: cache!
    @chain = chain
    @namespace = chain.namespace
    @transaction = transaction
    @transaction_hash = transaction_hash

    unless @transaction
      syncer = @chain.syncer
      @raw_transaction = syncer.get_transaction( transaction_hash )
    end
    raise RuntimeError.new("Could not retrieve transaction: #{transaction_hash}") if @transaction.nil? && @raw_transaction.nil?
  end

  def to_param; hash; end

  def height
    if @transaction
      @transaction.height
    else
      @raw_transaction['height']
    end
  end

  def hash
    @transaction_hash
  end

  def dump
    if @transaction
      @transaction.raw_transaction.as_json
    else
      @raw_transaction.as_json
    end
  end

  def amount_raw( denom: nil, from: nil, to: nil )
    unless @transaction || @raw_transaction
      return 0 unless @transaction.error_message&.nil? || !@raw_transaction['logs'][0]['success']
    end

    if @transaction
      msgs = @transaction.message.select { |msg| msg['type'] == get_amount_msg_type }
    else
      msgs = @raw_transaction['tx']['value']['msg'].select { |msg| msg['type'] == get_amount_msg_type }
    end

    if from
      msgs = msgs.select { |msg| msg['value']['from_address'] == from }
    end

    if to
      msgs = msgs.select { |msg| msg['value']['to_address'] == to }
    end

    msgs.inject(0) do |acc, msg|
      amount = msg['value']['amount'].is_a?(Array) ?
        msg['value']['amount'] :
        [msg['value']['amount']]

      acc + amount.inject(0) do |acc2, amount2|
        next acc2 if amount2['denom'] != denom
        acc2 + amount2['amount'].to_f
      end
    end
  end

  def fees_raw( denom: nil )
    denom ||= @chain.primary_token
    if @transaction
      raw_tx = @transaction.raw_transaction
    else
      raw_tx = @raw_transaction['tx']
    end

    raw_tx['value']['fee']['amount'].inject(0) do |acc, fee|
      next acc if fee['denom'] != denom
      acc + fee['amount'].to_f
    end
  rescue
    0
  end

  def gas_raw
    if @transaction
      @transaction.gas_wanted.to_i
    else
      @raw_transaction['tx']['value']['fee']['gas'].to_i
    end
  end

  def fees
    if @transaction
      raw_tx = @transaction.raw_transaction
    else
      raw_tx = @raw_transaction['tx']
    end

    raw_tx['value']['fee']['amount'].map do |fee|
      next if fee['denom'].blank?
      format_amount( fee['amount'].to_i, @chain, denom: fee['denom'] )
    end.compact
  rescue
    []
  end

  def gas
    format_amount( gas_raw, @chain, denom: 'gas' )
  end

  def error?
    return true if @transaction&.error_message || @raw_transaction&.has_key?('error')

    if @transaction
      code = @transaction.error_message
    else
      code = @raw_transaction['code']
      case code
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
        when 103 then "Validator Not Jailed"
        else "Unknown Error"
      end
    end

    !code.nil? && code != 0
  end

  def error_message
    if @transaction
      @transaction.error_message
    else
      @raw_transaction['tx']['error_message']
    end
  end

  def type
    if @transaction
      @transaction.transaction_type
    else
      @raw_transaction['tx']['type']
    end
  end

  def tags
    tags = @object['tags']
    (tags||[]).map { |tag| @namespace::Transactions::TagDecorator.new( tag, @chain ) }
  end

  def messages
    if @transaction
      (@transaction.message||[]).map { |msg| @namespace::Transactions::MessageDecorator.new( msg, @chain ) }
    else
      (@raw_transaction['tx']['value']['msg']||[]).map { |msg| @namespace::Transactions::MessageDecorator.new( msg, @chain ) }
    end
  end

  def gas_wanted
    if @transaction
      wanted = @transaction.gas_wanted
    else
      wanted = @raw_transaction['gas_wanted']
    end

    if !wanted.nil?
      format_amount( wanted.to_i, @chain, denom: 'gas' )
    else
      '&mdash;'.html_safe
    end
  end

  def gas_used
    if @transaction
      used = @transaction.gas_used
    else
      used = @raw_transaction['gas_used']
    end

    format_amount( used.to_i, @chain, denom: 'gas' )
  end

  def log
    if @transaction
      @transaction.logs.present? ? @transaction.logs[0]['log'] : @transaction.raw_transaction['raw_log']
    else
      @raw_transaction['log']
    end
  end

  def memo
    if @transaction
      @transaction.memo
    else
      @raw_transaction['tx']['value']['memo']
    end
  end

  def signatures
    if @transaction
      @transaction.signatures
    else
      @raw_transaction['tx']['value']['signatures']
    end
  end

  def timestamp
    if @transaction
      @transaction.timestamp.to_datetime.strftime('%d %b %Y at %H:%M UTC')
    else
      @raw_transaction['timestamp'].to_datetime.strftime('%d %b %Y at %H:%M UTC')
    end
  end

  def time_ago
    if @transaction
      timestamp = @transaction.timestamp
    else
      timestamp = @raw_transaction['timestamp']
    end
    "#{time_ago_in_words(@transaction.timestamp)} ago"
  end

  def chain_id
    @chain.slug
  end

  private

  def get_amount_msg_type
    'cosmos-sdk/MsgSend'
  end
end
