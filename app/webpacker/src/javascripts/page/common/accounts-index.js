$(document).ready( function() {
  console.log('here!')
  if( !_.includes(App.mode, 'accounts-index') ) { return }
  console.log('here!')
  new App.Common.AccountsTable( $('.transactions-table') ).render()
} )