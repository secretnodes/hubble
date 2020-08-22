$(document).ready( function() {
  if( !_.includes(App.mode, 'wallets-index') ) { return }

  new App.Common.DelegationModal( $('#delegation-modal') )
});