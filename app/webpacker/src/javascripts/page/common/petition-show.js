$(document).ready( function() {
  if( !_.includes(App.mode, 'petition-show') ) { return }
  console.log($('.vote-option input'));
  $('.vote-option input').on( 'change', ( e ) => {
    console.log('hi')
    const input = $(e.currentTarget)
    this.voteOption = input.val()
    input.parents('.vote-option').addClass('selected').siblings('.vote-option').removeClass('selected')
    $('.proposal-form').data( 'disabled', false )
    $('.submit-proposal-vote').removeAttr( 'disabled' )
  } );
});