$(document).ready( function() {
  if( !_.includes(App.mode, 'accounts-index') ) { return }

  new App.Common.AccountsTable( $('.transactions-table') ).render()
} )