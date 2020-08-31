class Common::Events::Swap < Common::Event
  def icon_name; 'exchange-alt'; end

  def positive?; true; end
  
  def amount
    transactionlike.message[0]['value']['AmountENG'].to_i
  end

  def twitter_msg
    "#{accountlike.address} swapped #{amount} ENG for SCRT."
  end

  def page_title
    "#{accountlike.address} swapped #{amount} ENG for SCRT."
  end
end