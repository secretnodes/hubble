class Cosmos::PreStartService < Cosmos::SyncBase

  def initialize( chain )
    super
    @state = @chain.syncer.get_consensus_state
    @genesis = @chain.syncer.get_genesis
  end

  def current_height
    @state['result']['round_state']['height']
  end

  def current_round
    @state['result']['round_state']['round']
  end

  def current_step
    @state['result']['round_state']['step']
  end

  def is_waiting_step?
    current_step == 3
  end

  def is_precommit_step?
    current_step >= 6
  end

  def validators
    genesis_validators = @genesis['result']['genesis']['validators']
    return [] if genesis_validators.nil?

    @state['result']['round_state']['validators']['validators'].map do |sd|
      genesis_info = genesis_validators.find { |gd| gd['pub_key']['value'] == sd['pub_key']['value'] }
      next if genesis_info.nil?

      bech32 = if sd.has_key?('consensus_pubkey')
        # cosmos 0.25.0+
        Cosmos::KeyConverter.pubkey_to_bech32( sd['consensus_pubkey']['value'], 'cosmosvalconspub' )
      else
        # older cosmos (8001 and before)
        Cosmos::KeyConverter.pubkey_to_bech32( sd['pub_key']['value'], 'cosmosvalpub' )
      end

      {
        addr: bech32,
        pub: sd['pub_key']['value'],
        power: genesis_info['power'].to_i,
        name: genesis_info['name']
      }
    end
  end

  def validator_states
    @_validator_states ||= validators.map.each_with_index do |val, i|
      next if val.nil?

      round = @state['result']['round_state']['votes'][current_round.to_i]
      votes = round['prevotes']
      precommits = round['precommits']

      prevoted = votes[i] != 'nil-Vote'
      precommited = precommits[i] != 'nil-Vote'

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
    end.compact
  end

  def percentage
    total = 0.0
    accum = 0.0
    validator_states.each do |state|
      total += state[:power]
      if state[:in_good_standing]
        accum += state[:power]
      end
    end

    if total == 0
      return 0
    else
      (accum / total) * 100.0
    end
  end

end
