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
      puts "No unprocessed local blocks. Therefore no new validators."
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

      new_validators = 0
      (from..to).to_a.in_groups_of(500, false).each do |heights|
        chunk_start_time = Time.now.utc.to_f
        blocks = @chain.blocks.where( height: heights ).reorder('height ASC')

        if blocks.count != heights.count
          puts "\n\nExpected the following block heights to exist -- #{heights - blocks.map(&:height)}!"
          puts "Looking for #{heights.inspect}, got #{blocks.map(&:height).inspect}"
          exit 1
        end

        blocks.each do |block|
          # puts "\t\t#{block.height}"
          # create any new validators we haven't seen before
          all_addresses = block.precommitters + block.validator_set.keys
          to_create = all_addresses.uniq - existing_validators.keys
          to_create.each do |new_addr|
            v = @chain.validators.create( address: new_addr,
                                          first_seen_at: block.timestamp )
            new_validators += 1
            # puts "ADDED VALIDATOR: #{new_addr} #{v.valid?}"
            existing_validators[new_addr] = v
          end

          existing_validators.values.each do |validator|
            if block.precommitters.include?( validator.address )
              latest_block_heights[validator.address] = block.height
              latest_precommit_totals[validator.address] += 1
            end
          end
        end

        ProgressReport.instance.progress from, (from + blocks.last.height), to
        ProgressReport.instance.benchmark (Time.now.utc.to_f - chunk_start_time) / 500
      end

      existing_validators.values.each do |validator|
        # puts "\t#{validator.address}\tVP: #{latest_voting_powers[validator.address]} LSB: #{latest_block_heights[validator.address]}"
        next if validator.latest_block_height == latest_block_heights[validator.address]
        validator.assign_attributes(
          latest_block_height: latest_block_heights[validator.address],
          total_precommits: latest_precommit_totals[validator.address]
        )
        validator.save if validator.changed?
      end

      ProgressReport.instance.report "Detected #{new_validators} new validators!"
    end
  end

  def sync_validator_metadata!
    syncer = Cosmos::SyncBase.new(@chain)
    stake_info = syncer.get_stake_info

    if stake_info.nil?
      puts "No stake info, cannot sync metadata."
      return
    end

    indexed_stake_info = stake_info.index_by { |info| info['pub_key'] }
    validators = @chain.validators
    total = validators.count

    ProgressReport.instance.start "Updating #{validators.count} Cosmos/#{@chain.name} validators metadata..."

    validators.each_with_index do |validator, i|
      # next if validator.latest_block_height.nil?
      validator_start_time = Time.now.utc.to_f

      begin
        validator_set_result = syncer.get_validator_set validator.latest_block_height
        validator_in_set = validator_set_result['result']['validators'].find { |v| v['address'] == validator.address }
        amino_pub_key = validator_in_set['pub_key']['value']

        bech32_key = Cosmos::KeyConverter.pubkey_to_bech32( amino_pub_key )

        validator.update_attributes info: indexed_stake_info[bech32_key]
      rescue
        puts "Could not get validator info for #{validator}\n\n#{$!.message}\n#{$!.backtrace.join("\n")}\n\n"
        next
      end

      ProgressReport.instance.progress 0, i+1, total
      ProgressReport.instance.benchmark Time.now.utc.to_f - validator_start_time
    end

    ProgressReport.instance.report
  end
end
