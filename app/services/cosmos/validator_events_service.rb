class Cosmos::ValidatorEventsService
  EVENT_ORDER = %w{
    active_set_inclusion
    voting_power_change
    n_of_m
    n_consecutive
  }

  def initialize( chain )
    @chain = chain
  end

  def run!
    definitions = @chain.validator_event_defs.group_by { |defn| defn['kind'] }

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

  def run_n_consecutive!( defn_id, n )
    from = @chain.get_event_height( defn_id )+1
    to = @chain.latest_local_height

    if to < from
      puts "No new local blocks to generate n-consecutive threshold events."
    else
      existing_validators = @chain.validators.index_by(&:address)
      latches = existing_validators.values.each_with_object({}) do |v, h|
        h[v.address] = Cosmos::ValidatorEventLatch.find_or_create_by(
          chain_id: @chain.id,
          validator_id: v,
          event_definition_id: defn_id
        )
      end

      ProgressReport.instance.start "Updating n-consecutive (#{n} consecutive) threshold events (block #{from} -> #{to})..."

      bulk_insert_events( from, to ) do |worker, block|
        existing_validators.values.each do |validator|
          address = validator.address
          latch = latches[address]

          if latch.state.nil?
            latch.state = 0
          end

          # update the latch according to the event definition
          voted = block.precommitters.include?( address )
          new_state = latch.state + (voted ? 0 : 1)
          tripped = new_state >= n

          if tripped
            if !latch.held?
              worker.add(
                type: 'Cosmos::ValidatorEvents::NConsecutive',
                chain_id: @chain.id,
                validator_id: validator.id,
                height: block.height,
                timestamp: block.timestamp,
                event_definition_id: defn_id,
                data: { n: n }
              )

              # make sure to hold the latch
              latch.assign_attributes held: true
            end
          else
            # make sure we dont hold the latch anymore, if we do
            latch.assign_attributes held: false
          end

          latch.assign_attributes state: new_state
        end
      end

      print "Saving updated latch state and holds... "
      latches.values.map(&:save)
      puts 'DONE'

      @chain.set_event_height! defn_id, to
      ProgressReport.instance.report
    end
  end

  def run_n_of_m!( defn_id, n, m )
    from = @chain.get_event_height( defn_id )+1
    to = @chain.latest_local_height

    if to < from
      puts "No new local blocks to generate n-of-m threshold events."
    else
      existing_validators = @chain.validators.index_by(&:address)
      latches = existing_validators.values.each_with_object({}) do |v, h|
        h[v.address] = Cosmos::ValidatorEventLatch.find_or_create_by(
          chain_id: @chain.id,
          validator_id: v,
          event_definition_id: defn_id
        )
      end

      ProgressReport.instance.start "Updating n-of-m (#{n}-of-#{m}) threshold events (block #{from} -> #{to})..."

      bulk_insert_events( from, to ) do |worker, block|
        existing_validators.values.each do |validator|
          address = validator.address
          latch = latches[address]

          if latch.state.nil?
            latch.state = '0' * m
          end

          # update the latch according to the event definition
          voted = block.precommitters.include?( address )
          new_state = latch.state[1..-1] << (voted ? '0' : '1')
          tripped = new_state.count('1') >= n

          if tripped
            if !latch.held?
              worker.add(
                type: 'Cosmos::ValidatorEvents::NOfM',
                chain_id: @chain.id,
                validator_id: validator.id,
                height: block.height,
                timestamp: block.timestamp,
                event_definition_id: defn_id,
                data: { n: n, m: m }
              )

              # make sure to hold the latch
              latch.assign_attributes held: true
            end
          else
            # make sure we dont hold the latch anymore, if we do
            latch.assign_attributes held: false
          end

          latch.assign_attributes state: new_state
        end
      end

      print "Saving updated latch state and holds... "
      latches.values.map(&:save)
      puts 'DONE'

      @chain.set_event_height! defn_id, to
      ProgressReport.instance.report
    end
  end

  def run_voting_power_change!( defn_id )
    from = @chain.get_event_height( defn_id )+1
    to = @chain.latest_local_height

    if to < from
      puts "No new local blocks to generate voting power change events."
    else
      existing_validators = @chain.validators.index_by(&:address)

      latest_voting_powers = existing_validators.values.each_with_object({}) do |v, h|
        h[v.address] = v.current_voting_power
      end

      ProgressReport.instance.start "Updating voting power change history (block #{from} -> #{to})..."

      get_active_set_changes = ->( blocks ) do
        Cosmos::ValidatorEvents::ActiveSetInclusion
          .where( chain: @chain, height: blocks.map(&:height) )
          .group_by( &:height )
      end

      bulk_insert_events( from, to, get_active_set_changes ) do |worker, block, active_set_changes|
        active_set_changes = (active_set_changes||[]).index_by( &:validator_id )

        block.validator_set.each do |address, voting_power|
          # sanity check to make sure we have this validator
          if !existing_validators.keys.include?( address )
            puts "\n\nExpected #{address} to exist in #{block.height}'s #{existing_validators.keys}!"
            exit 1
          end

          # find a potential active set change for this block
          active_set_change = active_set_changes[existing_validators[address].id]

          # if voting power changed from last time we saw it,
          # record an update. but *skip this* if this change was
          # part of being removed from the active set
          should_record = latest_voting_powers[address] != voting_power &&
                          (!active_set_change || active_set_change.positive?)
          # puts "\n\n#{address} / #{height}\tis active set change #{!active_set_change.nil?}\n#{existing_validators[address].first_seen_at}/#{block.timestamp} -> #{existing_validators[address].first_seen_at == block.timestamp}\npositive? #{active_set_change.try(:positive?) || false}\nvoting power changed? #{latest_voting_powers[address] != voting_power}\nSHOULD RECORD? #{should_record}"
          if should_record
            worker.add(
              type: 'Cosmos::ValidatorEvents::VotingPowerChange',
              chain_id: @chain.id,
              validator_id: existing_validators[address].id,
              height: block.height,
              timestamp: block.timestamp,
              event_definition_id: defn_id,
              data: { from: latest_voting_powers[address], to: voting_power }
            )
            latest_voting_powers[address] = voting_power
          end
        end
      end

      existing_validators.values.each do |validator|
        # puts "\t#{validator.address}\tVP: #{latest_voting_powers[validator.address]} LSB: #{latest_block_heights[validator.address]}"
        validator.update_attributes current_voting_power: latest_voting_powers[validator.address]
      end

      @chain.set_event_height! defn_id, to
      ProgressReport.instance.report
    end
  end

  def run_active_set_inclusion!( defn_id )
    from = @chain.get_event_height( defn_id )+1
    to = @chain.latest_local_height

    if to < from
      puts "No new local blocks to generate active set inclusion events."
    else
      ProgressReport.instance.start "Generating validator in/out of active set events (block #{from} -> #{to})..."

      validators = @chain.validators.index_by(&:address)

      prev_block = @chain.blocks.find_by( height: from - 1 )
      bulk_insert_events( from, to ) do |worker, block|
        first_block = true if prev_block.nil?

        validators.keys.each do |address|
          next if validators[address].first_seen_at.nil? || block.timestamp < validators[address].first_seen_at

          in_set = block.validator_set.keys.include?(address)
          in_prev_set = first_block ? false : prev_block.validator_set.keys.include?(address)

          if in_prev_set && !in_set
            # puts "VALIDATOR #{address} left active set (#{block.height})"
            worker.add(
              type: 'Cosmos::ValidatorEvents::ActiveSetInclusion',
              chain_id: @chain.id,
              validator_id: validators[address].id,
              height: block.height,
              timestamp: block.timestamp,
              event_definition_id: defn_id,
              data: { status: 'removed' }
            )
          elsif !in_prev_set && in_set
            # puts "VALIDATOR #{address} joined active set (#{block.height})"
            worker.add(
              type: 'Cosmos::ValidatorEvents::ActiveSetInclusion',
              chain_id: @chain.id,
              validator_id: validators[address].id,
              height: block.height,
              timestamp: block.timestamp,
              event_definition_id: defn_id,
              data: { status: 'added' }
            )
          else
            # no change
          end
        end

        prev_block = block
      end

      @chain.set_event_height! defn_id, to
      ProgressReport.instance.report
    end
  end

  private

  def bulk_insert_events( from, to, extra_arg_proc=nil, &process )
    Cosmos::ValidatorEvent.bulk_insert do |worker|
      (from..to).to_a.in_groups_of(500, false).each do |heights|
        blocks = @chain.blocks.where( height: heights ).reorder('height ASC')

        if blocks.count != heights.count
          puts "\n\nExpected the following block heights to exist -- #{heights - blocks.map(&:height)}!"
          puts "Looking for #{heights.inspect}, got #{blocks.map(&:height).inspect}"
          exit 1
        end

        extra_arg = extra_arg_proc ? extra_arg_proc.call( blocks ) : nil

        blocks.each do |block|
          block_start_time = Time.now.utc.to_f

          args = [ worker, block, extra_arg ? extra_arg[block.height] : nil ].compact
          process.call( *args )

          ProgressReport.instance.progress from, block.height, to
          ProgressReport.instance.benchmark Time.now.utc.to_f - block_start_time
        end
      end
    end
  end

  def defn_params( defn )
    case defn['kind']
    when 'voting_power_change' then [ defn['unique_id'] ]
    when 'active_set_inclusion' then [ defn['unique_id'] ]
    when 'n_of_m' then [ defn['unique_id'], defn['n'], defn['m'] ]
    when 'n_consecutive' then [ defn['unique_id'], defn['n'] ]
    end
  end

  def defn_is_valid?( defn )
    case defn['kind']
    when 'voting_power_change' then true
    when 'active_set_inclusion' then true
    when 'n_of_m'
      defn['n'].is_a?(Numeric) &&
      defn['m'].is_a?(Numeric) &&
      defn['n'] < defn['m']
    when 'n_consecutive'
      defn['n'].is_a?(Numeric)
    else
      false
    end
  end

end
