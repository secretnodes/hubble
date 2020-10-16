$(document).ready( function() {
  if( !_.includes(App.mode, 'governance-proposal') ) { return }

  new App.Common.GovProposalDepositModal( $('#proposal-deposit-modal') )
  new App.Common.GovProposalVoteModal( $('#proposal-vote-modal') )

  $('.collapse-comments-btn').click(function() {
    $('.comments').toggleClass('d-none');
    $(this).toggleClass('d-none');
    $('.comment-sort-btn').toggleClass('d-none');
    $('.show-comments-btn').toggleClass('d-none');
  });

  $('.show-comments-btn').click(function() {
    $('.comments').toggleClass('d-none');
    $(this).toggleClass('d-none');
    $('.comment-sort-btn').toggleClass('d-none');
    $('.collapse-comments-btn').toggleClass('d-none');
  });
} )
