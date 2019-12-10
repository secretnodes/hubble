$(document).ready( function() {
  if( !_.includes(App.mode, 'governance-proposal') ) { return }

  new App.Common.GovProposalDepositModal( $('#proposal-deposit-modal') )
  new App.Common.GovProposalVoteModal( $('#proposal-vote-modal') )
} )
