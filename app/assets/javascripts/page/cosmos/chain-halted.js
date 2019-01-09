$(document).ready( function() {
  if( !_.includes(App.mode, 'chain-halted') ) { return }

  new App.Cosmos.ValidatorTable( $('.validator-table') ).render()
} )
