class Common::Transactions::MessageDecorator
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include FormattingHelper
  include NamespacedChainsHelper

  def initialize( json, chain )
    @object = json
    @chain = chain
  end

  def type( tooltip: true )
    if tooltip
      tag.span(
        data: { toggle: 'tooltip', tooltip_side: 'right' },
        title: @object['type']
      ) { humanized_type }
    else
      humanized_type
    end
  end

  def each_info( &block )
    @object['value'].each do |k, v|
      fn = :"handle_#{k}"

      value = respond_to?(fn, true) ? send(fn, v) : v
      yield k, nice_info_key(k), value
    end
  end

  def humanize_message
    data = @object['value']
    case humanized_type
    when "Withdraw All Rewards", "Withdraw Rewards"
      "#{handle_account( data['delegator_address'] )} withdrew rewards from #{handle_validator( data['validator_address'], html: true)}".html_safe
    when "Withdraw Commission"
      "#{handle_validator(data['validator_address'], html: true)} withdrew commission".html_safe
    when "Redelegation".html_safe
      "#{handle_account( data['delegator_address'] )} redelegated #{handle_amount(data['amount'])} to #{handle_validator( data['validator_dst_address'], html: true)} from #{handle_validator( data['validator_src_address'], html: true)}".html_safe
    when "Undelegate"
      "#{handle_account( data['delegator_address'] )} undelegated #{handle_amount(data['amount'])} from #{handle_validator( data['validator_address'], html: true)}".html_safe
    when "Delegation"
      "#{handle_account( data['delegator_address'] )} delegated #{handle_amount(data['amount'])} to #{handle_validator( data['validator_address'], html: true)}".html_safe
    when "Deposit"
      "#{handle_account( data['delegator_address'] )} deposited #{handle_amount(data['amount'])} to #{data['proposal_id']}".html_safe
    when "Send"
      "#{handle_validator( data['from_address'], html: true)} sent #{handle_amount(data['amount'])} to #{handle_validator( data['to_address'], html: true)}".html_safe
    when 'Unjail'
      "#{handle_validator( data['address'], html: true)} unjailed".html_safe
    when "Swap"
      "#{handle_validator( data['Receiver'], html: true)} swapped #{format_amount(data['AmountENG'].to_f, denom: 'eng')} | #{handle_eth_tx(data['BurnTxHash'], 'View on Etherscan')}".html_safe
    when "Vote"
      "#{handle_validator( data['voter'], html: true)} voted #{data['option']} on #{data['proposal_id']}".html_safe
    when "Edit Validator"
      "#{handle_validator( data['address'], html: true )} modified their validator".html_safe
    when 'Modify Withdraw Address'
      "#{handle_validator( data['delegator_address'], html: true)} changed their withdraw address".html_safe
    end
  end

  private

  def humanized_type
    sanitized = @object['type'].sub( /^cosmos-sdk\//, '' )
    case sanitized
    when 'MsgWithdrawValidatorRewardsAll' then 'Withdraw All Rewards'
    when 'MsgWithdrawDelegationReward' then 'Withdraw Rewards'
    when 'MsgWithdrawValidatorCommission' then 'Withdraw Commission'
    when 'MsgBeginRedelegate' then 'Redelegation'
    when 'MsgUndelegate' then 'Undelegate'
    when 'MsgDelegate' then 'Delegation'
    when 'MsgDeposit' then 'Deposit'
    when 'MsgSend' then 'Send'
    when 'MsgUnjail' then 'Unjail'
    when 'tokenswap/TokenSwap' then 'Swap'
    when 'MsgVote' then 'Vote'
    when 'MsgEditValidator' then 'Edit Validator'
    when 'MsgModifyWithdrawAddress' then 'Modify Withdraw Address'
    else sanitized
    end
  end

  def nice_info_key( key )
    case key
    when 'validator_address', 'validator_addr' then 'Validator'
    when 'delegator_address', 'delegator_addr' then 'Delegator'
    when 'depositor' then 'Depositor'
    when 'proposal_id' then 'Proposal'
    when 'delegation' then 'Delegation'
    when 'inputs' then 'Inputs'
    when 'outputs' then 'Outputs'
    when 'address' then 'Address'
    when 'coins' then 'Coins'
    when 'value' then 'Value'
    when 'to_address' then 'To'
    when 'from_address' then 'From'
    when 'amount' then 'Amount'
    else key
    end
  end

  def handle_amount( value_or_values )
    values = value_or_values.is_a?(Array) ? value_or_values : [value_or_values]
    values.map do |coin|
      format_amount( coin['amount'].to_i, @chain, denom: coin['denom'] )
    end.join.html_safe
  end
  alias :handle_delegation :handle_amount
  alias :handle_value :handle_amount

  def handle_validator( value, html: true)
    bytes = Bitcoin::Bech32.decode( value )[1]
    account_address = Bitcoin::Bech32.encode( @chain.class::PREFIXES[:account_address].sub(/1$/, ''), bytes )
    handle_account( account_address, html: html)
  end
  alias :handle_validator_address :handle_validator

  def handle_account( value, html: true)
    validator = @chain.accounts.find_by( address: value ).try(:validator)
    if validator
      link_to validator.short_name, namespaced_path( 'validator', validator )
    else
      tag.span( class: 'technical' ) do
        link_to value, namespaced_path( 'account', value )
      end
    end
  end
  alias :handle_depositor :handle_account
  alias :handle_delegator_address :handle_account
  alias :handle_address :handle_account
  alias :handle_to_address :handle_account
  alias :handle_from_address :handle_account
  alias :handle_Receiver :handle_account
  alias :handle_SignerAddr :handle_account

  def handle_proposal_id( value )
    p = @chain.governance_proposals.find_by( ext_id: value )
    return "Unknown" unless p
    link_to p.title.truncate( 30, separator: '...' ), namespaced_path( 'governance_proposal', p )
  end

  def handle_AmountENG( value )
    format_amount( value.to_f, @chain, denom: 'eng' )
  end

  def handle_eth_address( value )
    tag.span( class: 'technical' ) do
      link_to value, "https://etherscan.io/address/#{value}"
    end
  end
  alias :handle_EthereumSender :handle_eth_address

  def handle_eth_tx( value, message = nil)
    message ||= value
    tag.span( class: 'technical' ) do
      link_to message, "https://etherscan.io/tx/#{value}"
    end
  end
  alias :handle_BurnTxHash :handle_eth_tx

  def handle_send( value )
    return value.map do |input|
      tag.div( class: 'mb-1' ) do
        tag.div( class: 'mb-1 d-flex align-items-center' ) do
          handle_account( input['address'] )
        end +
        tag.span( class: 'fa fa-arrow-right text-sm mr-2 text-info' ) +
        handle_amount(input['coins'])
      end
    end.join.html_safe
  end
  alias :handle_inputs :handle_send
  alias :handle_outputs :handle_send
end
