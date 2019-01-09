class Cosmos::TransactionMessageDecorator
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include FormattingHelper

  def initialize( json, chain )
    @object = json
    @chain = chain
  end

  def type
    sanitized = @object['type'].sub( /^cosmos-sdk\//, '' )
    formatted = case sanitized
                when 'MsgWithdrawValidatorRewardsAll' then 'Withdraw All Validator Rewards'
                when 'MsgDelegate' then 'Delegation'
                when 'MsgDeposit' then 'Deposit'
                else sanitized
                end
    tag.span(
      data: { toggle: 'tooltip', tooltip_side: 'right' },
      title: @object['type']
    ) { formatted }
  end

  def each_info( &block )
    @object['value'].each do |k, v|
      fn = :"handle_#{k}"
      value = respond_to?(fn, true) ? send(fn, v) : v
      yield k, nice_info_key(k), value
    end
  end

  private

  def nice_info_key( key )
    case key
    when 'validator_addr' then 'Validator'
    when 'delegator_addr' then 'Delegator'
    when 'depositor' then 'Depositor'
    when 'proposal_id' then 'Proposal'
    when 'delegation' then 'Delegation'
    when 'inputs' then 'Inputs'
    when 'outputs' then 'Outputs'
    when 'address' then 'Address'
    when 'coins' then 'Coins'
    else key
    end
  end

  def handle_amount( value )
    format_amount( value['amount'].to_i, @chain, token_denom_override: value['denom'] )
  end
  alias :handle_delegation :handle_amount

  def handle_validator( value )
    bytes = Bitcoin::Bech32.decode( value )[1]
    account_address = Bitcoin::Bech32.encode( 'cosmos', bytes )
    handle_account( account_address )
  end
  alias :handle_validator_addr :handle_validator

  def handle_account( value )
    validator = @chain.accounts.find_by( address: value ).try(:validator)
    if validator
      link_to validator.short_name, cosmos_chain_validator_path( @chain, validator )
    else
      tag.span( class: 'technical' ) { value }
    end
  end
  alias :handle_depositor :handle_account
  alias :handle_delegator_addr :handle_account
  alias :handle_address :handle_account

  def handle_proposal_id( value )
    p = @chain.governance_proposals.find_by( chain_proposal_id: value )
    return "Unknown" unless p
    link_to proposal.title.truncate( 30, separator: '...' ), cosmos_chain_governance_proposal_path( @chain, id: p.to_param )
  end

  def handle_send( value )
    return value.map do |input|
      tag.div( class: 'mb-1' ) do
        tag.div( class: 'mb-1 d-flex align-items-center' ) do
          handle_account( input['address'] )
        end +
        tag.span( class: 'fa fa-arrow-right' ) +
        input['coins'].map { |coin| handle_amount(coin) }.join.html_safe
      end
    end.join.html_safe
  end
  alias :handle_inputs :handle_send
  alias :handle_outputs :handle_send
end
