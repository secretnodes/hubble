module FormattingHelper
  include ActionView::Helpers::NumberHelper

  def format_amount( amount, chain=nil, token_denom_override: nil )
    chain ||= @chain

    # first account for the scaling factor on this chain
    amount /= 10 ** chain.token_factor

    # 'amount' here can be huge, so let's decide on a denomination to display
    val, scale = if amount >= PETA then [(amount / PETA), 'P']
                 elsif amount >= TERA then [(amount / TERA), 'T']
                 elsif amount >= GIGA then [(amount / GIGA), 'G']
                 elsif amount >= MEGA then [(amount / MEGA), 'M']
                 elsif amount >= KILO then [(amount / KILO), 'k']
                 else [amount, '']
                 end

    %{
      <span class='technical'>#{round_if_whole( val, 3 )}</span>
      <span class='text-sm'>#{scale}#{token_denom_override || @chain.token_denom}</span>
    }.html_safe
  end

  def round_if_whole( num, precision=3 )
    return 0 if num.blank? || num.zero? || num.to_f.nan? || num.to_f.infinite?

    if precision == 0
      return num.round.floor
    end

    if num <= 0.00001
      # force printing with precision instead of scientific notation
      # and then strip on trailing 0s
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

end
