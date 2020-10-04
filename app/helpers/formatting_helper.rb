module FormattingHelper
  include ActionView::Helpers::NumberHelper

  def format_amount( amount, chain=nil, denom: nil, thousands_delimiter: true, hide_units: false, html: true, precision: 3, in_millions: false )
    chain ||= @chain
    denom = denom || chain.token_map[chain.primary_token]

    # first account for the scaling factor on this chain
    if denom == 'gas'
      # gas should not be scaled
      denom = 'GAS'
    elsif denom.in?(chain.token_map.keys)
      amount /= 10 ** chain.token_map[denom]['factor'].to_f
      denom = chain.token_map[denom]['display']
    elsif denom == 'eng'
      amount /= 10 ** 8.0
      denom = "ENG"
    end

    # 'amount' here can be huge, so let's decide on a denomination to display
    val, scale = if amount >= GIGA then [(amount / KILO), 'k']
                 elsif amount >= MEGA && in_millions then [(amount / MEGA), 'M']
                 else [amount, '']
                 end

    num_str = "#{number_with_delimiter(round_if_whole( val, precision ))}#{scale}"
    denom_str = hide_units ? '' : denom
    if html
      num_str = "<span class='text-monospace'>#{num_str}</span>"
      denom_str = "<span class='text-sm text-muted'>#{denom_str}</span>" unless denom_str.blank?
    end

    "#{num_str} #{denom_str}".strip.html_safe
  end

  def round_if_whole( num, precision=3 )
    return 0 if num.blank? || num.zero? || num.to_f.nan? || num.to_f.infinite?

    if precision == 0
      return num.round.floor
    end

    if num <= 0.0001
      # force printing with precision instead of scientific notation
      # and then strip off trailing 0s
      return 0 if num.round(5).zero?
      return ( "%.5f" % num ).sub( /0*$/, '' )
    end

    tries = 10
    while tries > 0
      rounded = num.round(precision)
      break if rounded != 0
      precision += 1
      tries -= 1
    end

    rounded.to_f.floor == rounded ? rounded.round(0).floor : rounded
  end

  def round_if_whole_with_delim( num, precision=3 )
    num = 0 if num.blank? || num.to_f.nan? || num.to_f.infinite?
    number_with_delimiter round_if_whole(num, precision)
  end

  def convert_to_usd(amount, latest_block = nil)
    latest_block ||= @latest_block
    number_to_currency(amount * latest_block.usd_price)
  end

end
