const PETA = 10 ** 15
const TERA = 10 ** 12
const GIGA = 10 ** 9
const MEGA = 10 ** 6
const KILO = 10 ** 3
const NONE = 1

window.getScale = ( data ) => {
  const max = _.maxBy( data, 'y' ).y
  if( max >= PETA ) { return [PETA, 'P'] }
  else if( max >= TERA ) { return [TERA, 'T'] }
  else if( max >= GIGA ) { return [GIGA, 'G'] }
  else if( max >= MEGA ) { return [MEGA, 'M'] }
  else if( max >= KILO ) { return [KILO, 'k'] }
  else { return [NONE, ''] }
}
