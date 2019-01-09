class Cosmos::TransactionTagDecorator
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  def initialize( json, chain )
    @key = Base64.decode64(json['key'])
    @value = Base64.decode64(json['value'])
    @chain = chain
  end

  def type
    formatted = case @key
                when 'action' then 'Action'
                when 'delegator' then 'Delegator'
                when 'destination-validator' then 'Validator'
                when 'source-validator' then 'Validator'
                when 'sender' then 'Sender'
                when 'recipient' then 'Recipient'
                else @key
                end

    tag.span(
      data: { toggle: 'tooltip', tooltip_side: 'right' },
      title: @key
    ) { formatted }
  end

  def value
    fn = :"handle_#{@key.underscore}"
    respond_to?(fn, true) ?
      send(fn, @value) :
      tag.span( class: 'technical' ) { @value }
  end

  private

  def handle_validator( value )
    bytes = Bitcoin::Bech32.decode( value )[1]
    account_address = Bitcoin::Bech32.encode( 'cosmos', bytes )
    handle_account( account_address )
  end
  alias :handle_destination_validator :handle_validator
  alias :handle_source_validator :handle_validator

  def handle_account( value )
    validator = @chain.accounts.find_by( address: value ).try(:validator)
    if validator
      link_to validator.short_name, cosmos_chain_validator_path( @chain, validator )
    else
      tag.span( class: 'technical' ) { value }
    end
  end
  alias :handle_delegator :handle_account
end
