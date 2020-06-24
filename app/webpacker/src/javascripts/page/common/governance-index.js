$(document).ready( function() {
  if( !_.includes(App.mode, 'governance-index') ) { return }

  new App.Common.GovProposalsTable( $('.gov-proposals-table') ).render()
  new App.Common.GovProposalSubmitModal( $('#proposal-modal') )
} )
