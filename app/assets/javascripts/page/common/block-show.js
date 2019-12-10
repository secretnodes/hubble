$(document).ready( function() {
  if( !_.includes(App.mode, 'block-show') ) { return }

  new App.Common.ValidatorTable( $('.validator-table'), ['precommits'] ).render()
  new App.Common.TransactionsTable( $('.transactions-table') ).render()
} )
