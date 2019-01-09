$(document).ready( function() {
  if( !_.includes(App.mode, 'governance-proposal') ) { return }

  setupVoteModal()
  setupDepositModal()
} )

function setupVoteModal() {
  const voteModal = $('#vote-modal')
  voteModal.find('.copy-button').hide()
  voteModal.on('shown.bs.modal', function() {
    const fromField = voteModal.find('input[name=from]')
    const optionField = voteModal.find('input[name=option]')

    function updateCliCommand() {
      const from = fromField.val()
      const option = optionField.filter(':checked').val()

      const command = from.length == 0 || option.length == 0 ? null :
        `./gaiacli tx gov vote ${voteModal.data('proposalId')} ${option} \\
    --from="${from}" \\
    --chain-id=${voteModal.data('chainId')} \\
    --trust-node --async`

      voteModal.find('pre.cli-command').text( command || 'Enter parameters...' )
      voteModal.find('.copy-button').toggle( !!command )
    }

    voteModal.on('change input', [fromField, optionField], updateCliCommand)
    updateCliCommand()

    const copyButton = voteModal.find('.copy-button')
    if( ClipboardJS.isSupported() ) {
      const clipboard = new ClipboardJS(
        copyButton.get(0),
        { text: (() => voteModal.find('pre.cli-command').text()),
          container: voteModal.get(0) }
      )
      clipboard.on( 'success', function() {
        copyButton.html("<span class='fa fa-check'></span> Copied!")
        setTimeout( (() => copyButton.html('Copy')), 2000 )
      } )
    }
    else {
      copyButton.attr( 'disabled', 'disabled' )
    }
  } )
}

function setupDepositModal() {
  const depositModal = $('#deposit-modal')
  depositModal.find('.copy-button').hide()
  depositModal.on('shown.bs.modal', function() {
    const fromField = depositModal.find('input[name=from]')
    const amountField = depositModal.find('input[name=amount]')

    function updateCliCommand() {
      const from = fromField.val()
      const amount = amountField.val()

      const command = from.length == 0 || amount.length == 0 ? null :
        `./gaiacli tx gov deposit ${depositModal.data('proposalId')} ${amount} \\
    --from="${from}" \\
    --chain-id=${depositModal.data('chainId')} \\
    --trust-node --async`

      depositModal.find('pre.cli-command').text( command || 'Enter parameters...' )
      depositModal.find('.copy-button').toggle( !!command )
    }

    depositModal.on('change input', [fromField, amountField], updateCliCommand)
    updateCliCommand()

    const copyButton = depositModal.find('.copy-button')
    if( ClipboardJS.isSupported() ) {
      const clipboard = new ClipboardJS(
        copyButton.get(0),
        { text: (() => depositModal.find('pre.cli-command').text()),
          container: depositModal.get(0) }
      )
      clipboard.on( 'success', function() {
        copyButton.html("<span class='fa fa-check'></span> Copied!")
        setTimeout( (() => copyButton.html('Copy')), 2000 )
      } )
    }
    else {
      copyButton.attr( 'disabled', 'disabled' )
    }
  } )
}
