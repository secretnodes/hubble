const SI_SYMBOL = ["", "k", "M", "B"]

function abbreviateMoney( number, symbol ) {
  const tier = Math.log10(number) / 3 | 0
  if( tier == 0 ) { return number + symbol }

  const suffix = SI_SYMBOL[tier]
  const scale = Math.pow( 10, tier * 3 )
  const scaled = number / scale

  const rounded = Math.floor(scaled) == scaled ? scaled.toFixed(0) : scaled.toFixed(1)

  return `${rounded}${suffix}<span style='font-family: sans-serif;'>${symbol}</span>`
}
