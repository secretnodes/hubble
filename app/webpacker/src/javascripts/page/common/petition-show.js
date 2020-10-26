$(document).on( 'turbolinks:load', function() {
  if( !_.includes(App.mode, 'petition-show') ) { return }
  $('.vote-option input').on( 'change', ( e ) => {
    console.log('hi')
    const input = $(e.currentTarget)
    this.voteOption = input.val()
    input.parents('.vote-option').addClass('selected').siblings('.vote-option').removeClass('selected')
    $('.proposal-form').data( 'disabled', false )
    $('.submit-proposal-vote').removeAttr( 'disabled' )
  } );

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
  })
});