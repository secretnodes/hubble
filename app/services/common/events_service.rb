class Common::EventsService
  EVENT_ORDER = %w{
    swaps
    proposals
  }

  def initialize( chain )
    @chain = chain
  end

  def run!
    definitions = @chain.event_defs.group_by { |defn| defn['kind'] }

    EVENT_ORDER.each do |kind|
      next unless definitions[kind] # chain has no definitions of this kind
      definitions[kind].each do |defn|
        if defn_is_valid? defn
          puts "Running event (chain: #{@chain.name}) definition: #{defn['kind']} #{defn['unique_id']}..."
          self.public_send(:"run_#{defn['kind']}!", *defn_params(defn))
        end
      end
    end
  end

  def run_swaps!(defn_id)
    from = @chain.get_event_height( defn_id )+1
    swaps = Secret::Transaction.swap.where('height > ?', from).reverse
    
    swaps.each do |swap|
      begin
        account = @chain.namespace::Account.find_by_address(swap.message[0]['value']['Receiver'])

        Common::Events::Swap.create!(
          chainlike: swap.chain,
          accountlike: account,
          transactionlike: swap,
          height: swap.height,
          timestamp: swap.timestamp,
          data: { amount: swap.message[0]['value']['AmountENG'].to_i, denom: 'uscrt' },
          type: 'Common::Events::Swap',
          chainlike_type: 'Secret::Chain',
          accountlike_type: 'Secret::Account',
          transactionlike_type: 'Secret::Transaction'
        )

        @chain.set_event_height! defn_id, swap.height
      rescue StandardError => e
        puts swap.height
      ensure
        @chain.set_event_height! defn_id, swap.height
        next
      end
    end
  end

  def run_proposals!(defn_id)
    from = @chain.get_event_height( defn_id )+1
    proposals = Secret::Transaction.submit_proposal.where('height > ?', from).reverse
    
    proposals.each do |proposal|
      begin
        account = @chain.namespace::Account.find_by_address(proposal.message[0]['value']['proposer'])
        Common::Events::Proposal.create!(
          chainlike: proposal.chain,
          accountlike: account,
          transactionlike: proposal,
          proposallike: proposal.proposal,
          height: proposal.height,
          timestamp: proposal.timestamp,
          data: { deposit: proposal.message[0]['value']['initial_deposit'] },
          type: 'Common::Events::Proposal',
          chainlike_type: 'Secret::Chain',
          accountlike_type: 'Secret::Account',
          transactionlike_type: 'Secret::Transaction',
          proposallike_type: 'Secret::Governance::Proposal'
        )

        @chain.set_event_height! defn_id, proposal.height
      rescue StandardError => e
        puts proposal.height
      ensure
        @chain.set_event_height! defn_id, proposal.height
        next
      end
    end
  end

  private

  def defn_params( defn )
    case defn['kind']
    when 'swaps' then [ defn['unique_id'] ]
    when 'proposals' then [ defn['unique_id'] ]
    end
  end

  def defn_is_valid?( defn )
    case defn['kind']
    when 'swaps' then true
    when 'proposals' then true
    else
      false
    end
  end
end
