class Common::Events::Swap < Common::Event
  include FormattingHelper
  def icon_name; 'exchange-alt'; end

  def positive?; true; end
  
  def amount
    transactionlike.message[0]['value']['AmountENG'].to_i
  end

  def twitter_msg
    "#{accountlike.address} swapped #{format_amount(amount, chainlike, denom: 'eng', hide_units: true, in_millions: true, html: false) } ENG for SCRT."
  end

  def page_title
    "#{accountlike.address} swapped #{format_amount(amount, chainlike, denom: 'eng', hide_units: true, in_millions: true)} ENG for SCRT."
  end
end