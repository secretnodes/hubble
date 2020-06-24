//= require moment/min/moment.min
//= require moment-timezone/builds/moment-timezone.min

$(document).ready( function() {
  $('[data-toggle="tooltip"]').each( function() {
    const el = $(this)
    el.tooltipster( {
      contentAsHTML: true,
      interactive: true,
      trigger: 'hover',
      arrow: false,
      theme: 'tooltipster-puzzle',
      side: el.data('tooltip-side') || 'bottom',
      viewportAware: true,
      animationDuration: 100,
      delay: [0, 600],
      functionBefore: function( instance, helper ) {
        $.each( $.tooltipster.instances(), function( i, instance ) {
          instance.close()
        } )
      }
    } )
  } )

  if (localStorage.getItem('cookieSeen') != 'shown') {
    $('.cookie-banner').delay(2000).fadeIn();
    localStorage.setItem('cookieSeen', 'shown')
  };

  $('.close').click(function() {
    $('.cookie-banner').fadeOut();
  })
} )
