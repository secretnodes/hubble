class Cosmos::ValidatorEvents::VotingPowerChange < Cosmos::ValidatorEvent
  def icon_name; 'battery-half'; end

  THRESHOLD = 0.5 / 100.0

  class << self
    def validator_removed_from_active_set_in_same_block?
      !block.validator_in_set?( validator )
    end

    def significant_change?( from, to )
      return true if from.zero?
      ((to - from).abs / from.to_f) >= THRESHOLD
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
    return 100 if from.zero?
    num = to - from
    denom = from.to_f
    change = (num / denom) * 100.0
    round ? change.round(1) : change
  end
end
