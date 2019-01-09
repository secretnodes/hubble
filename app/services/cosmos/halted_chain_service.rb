class Cosmos::HaltedChainService < Cosmos::SyncBase
  def initialize( chain )
    super
    @state = get_consensus_state
    @genesis = get_genesis
  end

  def check_for_halted_chain!
    # puts "CHECKING FOR HALTED CHAIN [HALTED: #{@chain.halted}] - [LRS: #{@chain.last_round_state}] - [HAS_PEERS: #{has_peers?}] - [OVERDUE: #{round_overdue?}] - [NOTPROGRESSING: #{round_not_progressing?}] - [NOTADVANCING: #{block_not_advancing?}]]"
    ProgressReport.instance.start "Checking for halted state on Cosmos/#{@chain.name}..."
    if has_peers? && round_not_progressing? && block_not_advancing?
      @chain.has_halted! unless @chain.halted?
      ProgressReport.instance.report 'HALTED'
    else
      @chain.progressing! if @chain.halted?
      @chain.record_round_state(round_state_string)
      ProgressReport.instance.report 'OK'
    end
  end

  def round_state_details
    @state['result']['round_state']
  end

  def height
    @state['result']['round_state']['height']
  end

  def round
    @state['result']['round_state']['round']
  end

  def step
    @state['result']['round_state']['step']
  end

  def round_state_string
    "#{height}/#{round}/#{step}"
  end

  def is_waiting_step?
    step == 3
  end

  def is_precommit_step?
    step >= 6
  end

  def start_time
    Time.parse @state['result']['round_state']['start_time']
  end

  def proposer
    address = @state['result']['round_state']['validators']['proposer']['address']
    @chain.validators.find_by( address: address ) || address
  end

  def validator_name_from_genesis( address )
    found = @genesis['result']['genesis']['validators'].find do |val_info|
      val_info['address'] == address
    end

    found ? found['name'] : nil
  end

  def validators
    raw = @state['result']['round_state']['last_validators']['validators']
    raw.map.each_with_index do |val_info, i|
      validator = @chain.validators.find_by( address: val_info['address'] )
      # TODO: try to use genesis data to find moniker as well
      {
        index: i,
        address: val_info['address'],
        name: validator_name_from_genesis( val_info['address'] ),
        validator: validator,
        voting_power: val_info['voting_power'].to_i
      }
    end
  end

  def validator_states
    @_validator_states ||= validators.map do |val|
      round = @state['result']['round_state']['votes'][round.to_i]
      votes = round['prevotes']
      precommits = round['precommits']

      prevoted = votes[val[:index]] != 'nil-Vote'
      precommited = precommits[val[:index]] != 'nil-Vote'

      good = []
      bad = []

      if is_precommit_step?
        if precommited
          good << 'prevote'
          good << 'precommit'
        elsif prevoted
          good << 'prevote'
          bad << 'precommit'
        else
          bad << 'prevote'
          bad << 'precommit'
        end
      else
        if prevoted
          good << 'prevote'
        else
          bad << 'prevote'
        end
      end

      val[:good] = good
      val[:bad] = bad
      val[:in_good_standing] = bad.empty?
      val
    end
  end

  def percentage
    if true
      # Apparently we can't calculate this by voting power of validators
      # we'll just parse the string instead
      round_info = @state['result']['round_state']['votes'][round.to_i]
      votes_str = is_precommit_step? ? round_info['precommits_bit_array'] : round_info['prevotes_bit_array']
      percentage_str = votes_str.split('=').last
      return percentage_str.chomp.to_f * 100.0
    else
      total = 0.0
      accum = 0.0
      validator_states.each do |state|
        total += state[:voting_power]
        if state[:in_good_standing]
          accum += state[:voting_power]
        end
      end

      if total == 0
        return 0
      else
        (accum / total) * 100.0
      end
    end
  end

  private

  def has_peers?
    get_peer_count > 0
  end

  def round_not_progressing?
    (round_state_string == @chain.last_round_state || @chain.last_round_state.empty?) && round_overdue?
  end

  def block_not_advancing?
    get_canonical_block_height <= @chain.latest_local_height
  end

  def round_duration
    Time.now.to_i - start_time.to_i
  end

  def round_overdue?
    round_duration > 1.minutes.to_i
  end
end
