class Cosmos::ValidatorEvent < ApplicationRecord
  belongs_to :chain, class_name: 'Cosmos::Chain'
  belongs_to :validator, class_name: 'Cosmos::Validator'
  default_scope { order('height DESC').order(%{
    CASE type when 'Cosmos::ValidatorEvents::NConsecutive' then 1
              when 'Cosmos::ValidatorEvents::NOfM' then 2
              when 'Cosmos::ValidatorEvents::VotingPowerChange' then 3
              when 'Cosmos::ValidatorEvents::ActiveSetInclusion' then 4
    end
  }) }

  def kind_string
    self.class.name.demodulize.underscore
  end

  def block
    chain.blocks.find_by( height: height ) ||
    Cosmos::Block.stub( chain, height )
  end

  def to_partial_path
    self.class.name.underscore
  end
end

require_dependency 'cosmos/validator_events/active_set_inclusion'
require_dependency 'cosmos/validator_events/voting_power_change'
require_dependency 'cosmos/validator_events/n_consecutive'
require_dependency 'cosmos/validator_events/n_of_m'
