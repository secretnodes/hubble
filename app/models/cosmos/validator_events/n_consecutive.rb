class Cosmos::ValidatorEvents::NConsecutive < Cosmos::ValidatorEvent
  def icon_name; 'exclamation-circle'; end

  def positive?; false; end

  def n
    data['n']
  end
end
