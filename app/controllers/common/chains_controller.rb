class Common::ChainsController < Common::BaseController
  before_action :ensure_chain, only: %i{ show search }
  include FormattingHelper

  def show
    @validators = @chain.validators
    @governance = @chain.governance

    @current_price = @latest_block.usd_price

    chain_ids = @chain.namespace::Chain.where(testnet: @chain.testnet?).pluck(:id)
    raw_transactions = @chain.namespace::Transaction.swap.where(chain_id: chain_ids).reorder(timestamp: :desc)

    @total_swap = 0
    raw_transactions.each do |tx|
      @total_swap += tx.message[0]['value']['AmountENG'].to_f
    end

    @market_cap = format_amount(@total_swap, @chain, denom: 'eng', hide_units: true, html: false).gsub(',', '').to_i * @current_price

    page_title @chain.network_name, @chain.name, 'Overview', 'Validators, Governance, and Community Pool'
    meta_description "#{@chain.network_name} -- #{@chain.name} list of Validators, Address/Name, Voting Power, Uptime, Current Block and Governance"

    if @latest_block.nil?
      redirect_to namespaced_path( 'prestart', pre_path: true )
    end
  end

  def search
    query = params[:query].strip

    if query =~ /^\d+$/
      redirect_to namespaced_path( 'block', query )

    elsif query.downcase.starts_with?( @chain.prefixes[:account_address] )
      redirect_to namespaced_path( 'account', query.downcase )

    elsif query.downcase.starts_with?( @chain.prefixes[:validator_operator_address] )
      validator = @chain.validators.find_by( owner: query.downcase )
      if validator.nil?
        render template: 'common/chains/search_failed'
        return
      else
        redirect_to namespaced_path( 'validator', validator )
      end

    elsif query.upcase == query
      redirect_to namespaced_path( 'transaction', query )

    else
      if query.length >= 3
        # maybe try to find via validator moniker?
        validator = @chain.validators.where( 'moniker ILIKE ?', "%#{query}%" ).reorder('current_voting_power DESC')
        if validator.any?
          redirect_to namespaced_path( 'validator', validator.first )
          return
        end

        # how about a transaction then?
        tx = @chain.syncer(250).get_transaction( query )
        if tx
          redirect_to namespaced_path( 'transaction', tx['txhash'] )
          return
        end
      end

      render template: 'common/chains/search_failed'
      return

    end
  end

  def halted
    if action_name == 'halted' && !(@chain.halted? || Rails.env.development?)
      redirect_to namespaced_path
      return
    end
    render template: 'common/chains/halted'
  end
  alias :prestart :halted

  def broadcast
    tx = { tx: params[:payload], return: 'sync' }
    ok = !r.has_key?('code') && !r.has_key?('error')
    Rails.logger.error "\n\nBROADCAST RESULT: #{r.inspect}\n\n"
    render json: { ok: ok }.merge(r)
  end

  def info_cards
    @current_price = @latest_block.usd_price

    chain_ids = @chain.namespace::Chain.where(testnet: @chain.testnet?).pluck(:id)
    raw_transactions = @chain.namespace::Transaction.swap.where(chain_id: chain_ids).reorder(timestamp: :desc)

    @total_swap = 0
    raw_transactions.each do |tx|
      @total_swap += tx.message[0]['value']['AmountENG'].to_f
    end
    @market_cap = format_amount(@total_swap, @chain, denom: 'eng', hide_units: true, html: false).gsub(',', '').to_i * @current_price
    render partial: 'info_cards', chain: @chain, latest_block: @latest_block
  end
end
