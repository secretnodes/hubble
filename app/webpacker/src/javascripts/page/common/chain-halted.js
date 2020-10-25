$(document).on( 'turbolinks:load', function() {
  if( !_.includes(App.mode, 'chain-halted') ) { return }

  new App.Common.ValidatorTable( $('.validator-table') ).render()
} )
