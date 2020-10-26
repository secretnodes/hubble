$(document).on( 'turbolinks:load', function() {
  if( !_.includes(App.mode, 'block-show') ) { return }
  if ( window.validatorTable ) {
    window.validatorTable.destroy();
  }
  window.validatorTable = new App.Common.ValidatorTable( $('.validator-table'), ['precommits'] ).render()
} )
