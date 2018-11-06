class Cosmos::ValidatorEvents::ActiveSetInclusion < Cosmos::ValidatorEvent
  def icon_name; positive? ? 'link' : 'unlink'; end

  def positive?
    added?
  end

  def added?
    data['status'] == 'added'
  end

  def removed?
    !added?
  end
end
