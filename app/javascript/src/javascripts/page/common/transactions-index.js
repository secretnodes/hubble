$(document).on( 'turbolinks:load', function() {
  if( !_.includes(App.mode, 'transactions-index') ) { return }

  new App.Common.TransactionsTable( $('.transactions-table') ).render();
  if ( $('.swap-history-chart').html() != undefined ) {
    new App.Common.SwapHistory( $(`.swap-history-chart`) ).render()
  };
} )
