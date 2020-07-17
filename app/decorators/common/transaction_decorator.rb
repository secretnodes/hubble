class Common::TransactionDecorator
  include FormattingHelper
  include ActionView::Helpers::DateHelper

  def initialize( chain, transaction )
    # TODO: cache!
    @chain = chain
    @namespace = chain.namespace
    @transaction = transaction
    raise RuntimeError.new("Could not retrieve transaction: #{transaction_hash}") if @transaction.nil?
  end

  def to_param; hash; end

  def height
    @transaction.height
  end

  def hash
    @transaction.hash_id
  end

  def dump
    @transaction.raw_transaction.as_json
  end

  def amount_raw( denom: nil, from: nil, to: nil )
    if !@transaction.error_message.nil?
      return 0
    end

    msgs = @transaction.message.select { |msg| msg['type'] == get_amount_msg_type }

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
    @transaction.raw_transaction['value']['fee']['amount'].inject(0) do |acc, fee|
      next acc if fee['denom'] != denom
      acc + fee['amount'].to_f
    end
  rescue
    0
  end

  def gas_raw
    @transaction.gas_wanted.to_i
  end

  def fees
    @transaction.raw_transaction['value']['fee']['amount'].map do |fee|
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
    return true if @transaction.error_message

    code = @transaction.error_message

    !code.nil? && code != 0
  end

  def error_message
    @transaction.error_message
  end

  def type
    @transaction.transaction_type
  end

  def tags
    tags = @object['tags']
    (tags||[]).map { |tag| @namespace::Transactions::TagDecorator.new( tag, @chain ) }
  end

  def messages
    (@transaction.message||[]).map { |msg| @namespace::Transactions::MessageDecorator.new( msg, @chain ) }
  end

  def gas_wanted
    wanted = @transaction.gas_wanted

    if !wanted.nil?
      format_amount( wanted.to_i, @chain, denom: 'gas' )
    else
      '&mdash;'.html_safe
    end
  end

  def gas_used
    used = @transaction.gas_used

    format_amount( used.to_i, @chain, denom: 'gas' )
  end

  def log
    @transaction.logs[0]['log']
  end

  def memo
    @transaction.memo
  end

  def signatures
    @transaction.signatures
  end

  def timestamp
    @transaction.timestamp.to_datetime.strftime('%d %b %Y at %H:%M UTC')
  end

  def time_ago
    "#{time_ago_in_words(@transaction.timestamp)} ago"
  end

  private

  def get_amount_msg_type
    'cosmos-sdk/MsgSend'
  end
end
