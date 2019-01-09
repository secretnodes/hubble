$(document).ready( function() {
  if( !_.includes(App.mode, 'block-show') ) { return }

  new App.Cosmos.ValidatorTable( $('.validator-table'), ['last-seen'] ).render()
  new App.Cosmos.TransactionsTable( $('.transactions-table') ).render()
} )
