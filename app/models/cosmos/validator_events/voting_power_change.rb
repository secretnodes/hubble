class Cosmos::ValidatorEvents::VotingPowerChange < Cosmos::ValidatorEvent
  def icon_name; 'battery-half'; end

  class << self
    def validator_removed_from_active_set_in_same_block?
      !block.validator_in_set?( validator )
    end
  end

  def positive?
    percentage_change( false ) > 0
  end

  def from
    data['from'] || 0
  end

  def to
    data['to']
  end

  def percentage_change( round=true )
    if from == 0
      100
    else
      num = to - from
      denom = from.to_f
      change = (num / denom) * 100.0
      round ? change.round(1) : change
    end
  end
end
