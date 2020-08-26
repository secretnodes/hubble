$(document).ready( function() {
  if( !_.includes(App.mode, 'wallets-index') ) { return }

  new App.Common.DelegationModal( $('#delegation-modal') )
  new App.Common.RedelegationModal( $('#redelegation-modal') )
  new App.Common.SendModal( $('#send-modal') )
  new App.Common.UndelegateModal( $('#undelegate-modal') )

  $('.copy-button').each( function() {
    const copyButton = $(this)
    let ClipboardJS = require('clipboard');
    if( ClipboardJS.isSupported() ) {
      copyButton.show()
      const clipboard = new ClipboardJS(
        copyButton.get(0),
        { text: (() => copyButton.data('hash')) }
      )
      clipboard.on( 'success', function() {
        copyButton.html("<span class='fa fa-check'></span>")
        setTimeout( (() => copyButton.html("<span class='fa fa-copy'></span>")), 2000 )
      } )
    }
    else {
      copyButton.attr( 'disabled', 'disabled' )
    }
  } )
});