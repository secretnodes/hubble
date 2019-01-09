class Cosmos::ValidatorSyncService
  def initialize( chain )
    @chain = chain
  end

  def update_history_height!
    @chain.update_attributes history_height: @chain.latest_local_height
  end

  def sync_validator_timestamps!
    from = @chain.history_height+1
    to = @chain.latest_local_height

    if to < from
      puts "No unprocessed local blocks. Therefore no validator updates needed."
    else
      existing_validators = @chain.validators.index_by(&:address)

      # snapshot current voting power on each validator
      ProgressReport.instance.start "Snapshotting quick info for Cosmos/#{@chain.name} validators (blocks #{from} -> #{to})..."

      # figure out the last block each validator precommitted on
      latest_block_heights = existing_validators.values.each_with_object({}) do |v, h|
        h[v.address] = v.latest_block_height
      end
      latest_precommit_totals = existing_validators.values.each_with_object(Hash.new { |h,k| h[k] = 0 }) do |v, h|
        h[v.address] = v.total_precommits
      end
      latest_proposal_totals = existing_validators.values.each_with_object(Hash.new { |h,k| h[k] = 0 }) do |v, h|
        h[v.address] = v.total_proposals
      end
      latest_voting_powers = existing_validators.values.each_with_object({}) do |v, h|
        h[v.address] = v.current_voting_power
      end

      new_validators = 0
      (from..to).to_a.in_groups_of(500, false).each do |heights|
        chunk_start_time = Time.now.utc.to_f
        blocks = @chain.blocks.where( height: heights ).reorder('height ASC')

        if blocks.count != heights.count
          raise Cosmos::SyncBase::CriticalError.new("Expected the following block heights to exist -- #{(heights - blocks.map(&:height)).join(', ')}!")
        end

        blocks.each do |block|
          # puts "\t\t#{block.height}"
          # create any new validators we haven't seen before
          all_addresses = block.precommitters + block.validator_set.keys
          to_create = all_addresses.uniq - existing_validators.keys
          to_create.each do |new_addr|
            v = @chain.validators.create(
              address: new_addr,
              first_seen_at: block.timestamp
            )

            if v.persisted? && v.valid?
              new_validators += 1
              # puts "ADDED VALIDATOR: #{new_addr} #{v.valid?}"
              existing_validators[new_addr] = v
            elsif ENV['DEBUG']
              puts "Invalid validator found: #{new_addr.inspect}\nALL: #{all_addresses.inspect}\nTO CREATE: #{to_create.inspect}\n\n"
            end
          end

          existing_validators.values.each do |validator|
            if block.precommitters.include?( validator.address ) &&
               (latest_block_heights[validator.address] || 0) < block.height
              latest_block_heights[validator.address] = block.height
              latest_precommit_totals[validator.address] += 1
              latest_proposal_totals[validator.address] += 1 if block.proposer_address == validator.address
            end
            latest_voting_powers[validator.address] = block.validator_set[validator.address] || 0
          end
        end

        ProgressReport.instance.progress from, (from + blocks.last.height), to
        ProgressReport.instance.benchmark (Time.now.utc.to_f - chunk_start_time) / heights.count
      end

      existing_validators.values.each do |validator|
        # puts "\t#{validator.address}\tVP: #{latest_voting_powers[validator.address]} LSB: #{latest_block_heights[validator.address]}"
        validator.assign_attributes(
          latest_block_height: latest_block_heights[validator.address] || 0,
          total_precommits: latest_precommit_totals[validator.address] || 0,
          total_proposals: latest_proposal_totals[validator.address] || 0,
          current_voting_power: latest_voting_powers[validator.address] || 0,
          current_uptime: validator.calculate_current_uptime
        )
        validator.save! if validator.changed?
      end

      ProgressReport.instance.report "Detected #{new_validators} new validators!"
    end
  end

  def sync_validator_metadata!
    syncer = @chain.syncer
    stake_info = syncer.get_stake_info

    if stake_info.nil? || !stake_info.is_a?(Array)
      puts "No stake info, cannot sync metadata."
      return
    end

    if stake_info.first.has_key?('consensus_pubkey')
      # cosmos 0.25.0+
      key_prefix = 'cosmosvalconspub'
      indexed_stake_info = stake_info.index_by { |info| info['consensus_pubkey'] }
    else
      # older cosmos (8001 and before)
      key_prefix = 'cosmosvaladdr'
      indexed_stake_info = stake_info.index_by { |info| info['pub_key'] }
    end

    validators = @chain.validators
    total = validators.count

    ProgressReport.instance.start "Updating #{validators.count} Cosmos/#{@chain.name} validators metadata..."

    validators.each_with_index do |validator, i|
      if validator.address.blank?
        raise "EXPLODE #{validator.inspect}"
      end

      # next if validator.latest_block_height.nil?
      validator_start_time = Time.now.utc.to_f

      begin
        height = validator.latest_block_height.zero? ? @chain.latest_local_height : validator.latest_block_height
        validator_set_result = syncer.get_validator_set( height )
        validator_in_set = validator_set_result['result']['validators'].find { |v| v['address'] == validator.address }

        if validator_in_set.nil?
          extra_info = ENV['DEBUG'] ? " -- (set: #{validator_set_result['result']['validators'].map { |vi| vi['address'] }.inspect})" : ''
          raise RuntimeError.new("Validator #{validator.address} (id: #{validator.id}) not found in set for height #{height}#{extra_info}")
        end

        amino_pub_key = validator_in_set['pub_key']['value']
        bech32_key = Cosmos::KeyConverter.pubkey_to_bech32( amino_pub_key, key_prefix )

        validator.update_attributes info: indexed_stake_info[bech32_key]
      rescue
        puts "Could not get validator info for #{validator.address} -- #{$!.message}\n\n"
      end

      # is there an account with a matching address we should link to?
      begin
        account_address = Bitcoin::Bech32.encode(
          'cosmos',
          Bitcoin::Bech32.decode( validator.info['operator_address'] )[1]
        )
      rescue
        puts "No account/validator link found for: #{validator.address}" if ENV['DEBUG']
        account_address = nil
      end

      account = @chain.accounts.find_by( address: account_address )
      validator.update_attributes( account: account ) if account

      ProgressReport.instance.progress 0, i+1, total
      ProgressReport.instance.benchmark Time.now.utc.to_f - validator_start_time
    end

    ProgressReport.instance.report
  end
end
