moment.tz.setDefault('EST')

$(document).ready( function() {
  $('[data-toggle="tooltip"]').tooltipster( {
    contentAsHTML: true,
    interactive: true,
    trigger: 'hover',
    arrow: false,
    theme: 'tooltipster-hubble',
    side: 'right',
    viewportAware: true,
    delay: 25
  } )
} )
