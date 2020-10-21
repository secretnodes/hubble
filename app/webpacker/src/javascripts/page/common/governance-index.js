$(document).ready( function() {
  if( !_.includes(App.mode, 'governance-index') ) { return }

  $('#gov-page-selector').change( (e) => {
    window.location = $('#gov-page-selector :selected').val();
  })

  new App.Common.GovProposalsTable( $('.gov-proposals-table') ).render()
  new App.Common.GovProposalSubmitModal( $('#proposal-modal') )
} )
