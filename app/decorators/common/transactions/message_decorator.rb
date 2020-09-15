class Common::Transactions::MessageDecorator
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::NumberHelper
  include FormattingHelper
  include NamespacedChainsHelper

  def initialize( json, chain, logs )
    @object = json
    @chain = chain
    @logs = logs
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

  def humanize_message_short
    data = @object['value']
    case humanized_type
    when "Withdraw All Rewards", "Withdraw Rewards"
      "#{handle_account( data['delegator_address'] )} #{handle_badges('withdrew rewards')} from #{handle_validator( data['validator_address'], html: true)}".html_safe
    when "Withdraw Commission"
      "#{handle_validator(data['validator_address'], html: true)} #{handle_badges('withdrew commission')}".html_safe
    when "Redelegation".html_safe
      "#{handle_account( data['delegator_address'] )} #{handle_badges('redelegated')} #{handle_amount(data['amount'])} to #{handle_validator( data['validator_dst_address'], html: true)} from #{handle_validator( data['validator_src_address'], html: true)}".html_safe
    when "Undelegate"
      "#{handle_account( data['delegator_address'] )} #{handle_badges('undelegated')} #{handle_amount(data['amount'])} from #{handle_validator( data['validator_address'], html: true)}".html_safe
    when "Delegation"
      "#{handle_account( data['delegator_address'] )} #{handle_badges('delegated')} #{handle_amount(data['amount'])} to #{handle_validator( data['validator_address'], html: true)}".html_safe
    when "Deposit"
      "#{handle_account( data['depositor'] )} #{handle_badges('deposited')} #{handle_amount(data['amount'])} to #{data['proposal_id']}".html_safe
    when "Submit Proposal"
      handle_proposal_body( data )
    when "Send"
      "#{handle_validator( data['from_address'], html: true)} #{handle_badges('sent')} #{handle_amount(data['amount'])} to #{handle_validator( data['to_address'], html: true)}".html_safe
    when 'Unjail'
      "#{handle_validator( data['address'], html: true)} #{handle_badges('unjailed')} their secret node".html_safe
    when "Swap"
      "#{handle_validator( data['Receiver'], html: true)} #{handle_badges('swapped')} #{format_amount(data['AmountENG'].to_f, denom: 'eng')} | #{handle_eth_tx(data['BurnTxHash'], 'View on Etherscan')}".html_safe
    when "Vote"
      "#{handle_validator( data['voter'], html: true)} #{handle_badges('voted')} #{data['option']} on #{data['proposal_id']}".html_safe
    when "Edit Validator"
      "#{handle_validator( data['address'], html: true )} #{handle_badges('modified')} their validator".html_safe
    when 'Modify Withdraw Address'
      "#{handle_validator( data['delegator_address'], html: true)} #{handle_badges('changed')} their withdraw address".html_safe
    when 'Create Validator'
      "#{handle_validator( data['delegator_address'], html: true)} #{handle_badges('created')} a validator with moniker #{handle_validator(data['validator_address'])}".html_safe
    when 'Register'
      "#{handle_validator( data['sender'], html: true)} #{handle_badges('registered')} a new node.".html_safe
    when 'Store Contract Code'
      code_id = @logs.nil? ? '' : " with code ID #{@logs[0]['events'][0]['attributes'].select { |hash| hash['key'] == 'code_id' }.first['value']}"
      "#{handle_validator( data['sender'], html: true)} #{handle_badges('stored')} a new contract#{code_id}.".html_safe
    when 'Initialize Contract'
      "#{handle_validator( data['sender'], html: true)} #{handle_badges('initialized')} a new contract labeled #{data['label']} with code ID #{data['code_id']}.".html_safe
    when 'Execute Contract'
      "#{handle_validator( data['sender'], html: true)} #{handle_badges('executed')} a contract at #{handle_account( data['contract'])}.".html_safe
    end
  end

  def humanize_message_long
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
      "#{handle_account( data['depositor'] )} deposited #{handle_amount(data['amount'])} in support of proposal #{data['proposal_id']}: #{handle_proposal_id(data['proposal_id'])}.".html_safe
    when "Submit Proposal"
      handle_proposal_body( data )
    when "Send"
      "#{handle_validator( data['from_address'], html: true)} sent #{handle_amount(data['amount'])} to #{handle_validator( data['to_address'], html: true)}".html_safe
    when 'Unjail'
      "#{handle_validator( data['address'], html: true)} unjailed their validator.".html_safe
    when "Swap"
      "#{handle_eth_address( data['EthereumSender'])} swapped #{format_amount(data['AmountENG'].to_f, denom: 'eng')} for SCRT. Destination address: #{handle_validator( data['Receiver'], html: true)}.| #{handle_eth_tx(data['BurnTxHash'], 'View on Etherscan')}".html_safe
    when "Vote"
      "#{handle_validator( data['voter'], html: true)} voted #{data['option']} on proposal #{handle_proposal_id( data['proposal_id'] )}".html_safe
    when "Edit Validator"
      "#{handle_validator(data['address'])} modified their #{@chain.namespace.to_s.downcase} node. <br /> Changes to #{handle_validator(data['address'])}: <br /> #{handle_edit_validator( data )}".html_safe
    when 'Modify Withdraw Address'
      "#{handle_validator( data['delegator_address'], html: true)} changed their withdraw address".html_safe
    when 'Create Validator'
      "The #{handle_validator( data['delegator_address'], html: true)} secret node was created.".html_safe
    when 'Register'
      "#{handle_validator( data['sender'], html: true)} registered a new node.".html_safe
    when 'Store Contract Code'
      code_id = @logs.nil? ? '' : " with code ID #{@logs[0]['events'][0]['attributes'].select { |hash| hash['key'] == 'code_id' }.first['value']}"
      "#{handle_validator( data['sender'], html: true)} stored a new contract#{code_id}.".html_safe
    when 'Initialize Contract'
      code_id = data['code_id'].present? ? " with code ID #{data['code_id']}" : nil
      "#{handle_validator( data['sender'], html: true)} initialized a new contract labeled #{data['label']}#{code_id}.".html_safe
    when 'Execute Contract'
      code_id = data['code_id'].present? ? " with code ID #{data['code_id']}" : nil
      "#{handle_validator( data['sender'], html: true)} executed a contract at #{handle_account( data['contract'])}#{code_id}.".html_safe
    end
  end

  private

  def humanized_type
    sanitized = @object['type'].split('/').second
    case sanitized
    when 'MsgWithdrawValidatorRewardsAll' then 'Withdraw All Rewards'
    when 'MsgWithdrawDelegationReward' then 'Withdraw Rewards'
    when 'MsgWithdrawValidatorCommission' then 'Withdraw Commission'
    when 'MsgBeginRedelegate' then 'Redelegation'
    when 'MsgUndelegate' then 'Undelegate'
    when 'MsgDelegate' then 'Delegation'
    when 'MsgDeposit' then 'Deposit'
    when 'MsgSubmitProposal' then 'Submit Proposal'
    when 'MsgSend' then 'Send'
    when 'MsgUnjail' then 'Unjail'
    when 'TokenSwap' then 'Swap'
    when 'MsgVote' then 'Vote'
    when 'MsgEditValidator' then 'Edit Validator'
    when 'MsgModifyWithdrawAddress' then 'Modify Withdraw Address'
    when 'MsgCreateValidator' then 'Create Validator'
    when 'authenticate' then 'Register'
    when 'MsgStoreCode' then 'Store Contract Code'
    when 'MsgInstantiateContract' then 'Initialize Contract'
    when 'MsgExecuteContract' then 'Execute Contract'
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
    link_to p.title, namespaced_path( 'governance_proposal', p )
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

  def handle_edit_validator( value )
    modifications = value['description'].select { |k, v| v != "[do-not-modify]" }
    list_index = 1
    change_list = ''
    if value['commission_rate']
      change_list += "1. Commission Set to #{number_to_percentage(value['commission_rate'].to_f * 100, precision: 0)}. <br />"
      list_index += 1
    end

    modifications.each_with_index do |mod, i|
      change_list += "#{i + list_index}. #{mod[0]} set to #{mod[1]}. <br />"
    end

    return change_list
  end

  def handle_proposal_body( value )
    proposal = @chain.governance_proposals.find_by_title value['content']['value']['title']

    if proposal
      title = handle_proposal_id(proposal.ext_id)
    else
      title = value['content']['value']['title']
    end

    type = value['content']['type'].sub( /^cosmos-sdk\//, '' )

    if type == 'ParameterChangeProposal'
      type_humanized = 'parameter change proposal'
    else
      type_humanized = 'text change proposal'
    end

    "#{handle_validator(value['proposer'])} submitted a #{type_humanized} entitled #{title}.".html_safe
  end

  def handle_badges( value )
    text_color = "text-light" unless value == "undelegate" || value == "undelegated"
    tag.span(class: "badge badge-pill badge-light #{text_color} text-uppercase", style: "background-color: #{handle_color(value)}") do
      value
    end
  end

  def handle_color( value )
    color = case value.downcase
    when 'sent' || 'send'
      '#355070'
    when 'delegated' || 'delegate'
      '#E56B6F'
    when 'undelegated' || 'undelegate'
      '#EEEF20'
    when 'redelegated' || 'redelegate'
      '#2B9348'
    when 'submitted a proposal' || 'submit proposal'
      '#007F5F'
    when 'deposited' || 'deposit'
      '#55A630'
    when 'voted' || 'vote'
      '#AACC00'
    when 'swapped' || 'swap'
      '#B56576'
    when 'withdrew all rewards' || 'withdraw all rewards'
      '#F4CAE0'
    when 'withdrew rewards' || 'withdraw rewards'
      '#D7B9D5'
    when 'withdrew commission' || 'withdraw commission'
      '#ADA7C9'
    when 'unjailed' || 'unjail'
      '#EAAC8B'
    when 'modified' || 'edit'
      '#4ea8de'
    when 'changed' || 'modify withdraw address'
      '#90A8C3'
    when 'created' || 'create validator'
      '#64A6BD'
    when 'stored'
      '#78586F'
    when 'registered'
      '#C1DF1F'
    when 'executed'
      '#FF8552'
    when 'initialized'
      '#8AA2A9'
    end
  end
end
