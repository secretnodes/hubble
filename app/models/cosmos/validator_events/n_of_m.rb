class Cosmos::ValidatorEvents::NOfM < Cosmos::ValidatorEvent
  def icon_name; 'exclamation-circle'; end

  def positive?; false; end

  def n
    data['n']
  end

  def m
    data['m']
  end
end
