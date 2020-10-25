$(document).on( 'turbolinks:load', function() {
  setTimeout(
    function() {
      $('.auto-alert-hide').slideUp('fast')
    },
    4000
  )
} )
