$(document).ready( function() {
  if( !_.includes(App.mode, 'faucet-show') ) { return }

  const button = $('.submit-button')
  const form = button.parents('form')
  console.log(grecaptcha)
  grecaptcha.ready( function() {
    grecaptcha.render( button.get(0), {
      sitekey: button.data('sitekey'),
      callback: ( token ) => {
        button.attr('disabled', 'disabled')
        form.submit()
      }
    } )
  } )
} )
