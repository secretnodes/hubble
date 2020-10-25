$(document).on( 'turbolinks:load', function() {
  if( !_.includes(App.mode, 'block-show') ) { return }

  new App.Common.ValidatorTable( $('.validator-table'), ['precommits'] ).render()
  new App.Common.TransactionsTable( $('.transactions-table') ).render();
  if ( $('.swap-history-chart').html() != undefined ) {
    console.log($('.swap-history-chart').html());
    new App.Common.SwapHistory( $(`.swap-history-chart`) ).render()
  }
} )
