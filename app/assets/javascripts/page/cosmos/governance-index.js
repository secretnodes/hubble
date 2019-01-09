$(document).ready( function() {
  if( !_.includes(App.mode, 'governance-index') ) { return }

  new App.Cosmos.GovProposalsTable( $('.gov-proposals-table') ).render()

  setupProposalModal()
} )

function setupProposalModal() {
  const proposalModal = $('#proposal-modal')
  proposalModal.find('.copy-button').hide()
  proposalModal.on('shown.bs.modal', function() {
    const fromField = proposalModal.find('input[name=from]')
    const descriptionField = proposalModal.find('input[name=description]')
    const titleField = proposalModal.find('input[name=title]')
    const depositField = proposalModal.find('input[name=deposit]')

    function updateCliCommand() {
      const from = fromField.val()
      const description = descriptionField.val()
      const title = titleField.val()
      const deposit = depositField.val()

      const command = from.length == 0 || title.length == 0 ||
                      description.length == 0 || deposit.length == 0 ? null :
        `./gaiacli tx submit-proposal \\
    --title="${title}" \\
    --description="${description}" \\
    --type="Text" \\
    --deposit=${deposit} \\
    --from=${from} \\
    --chain-id=${proposalModal.data('chainId')} \\
    --trust-node --async`

      proposalModal.find('pre.cli-command').text( command || 'Enter parameters...' )
      proposalModal.find('.copy-button').toggle( !!command )
    }

    proposalModal.on('change input', [fromField, descriptionField, titleField, depositField], updateCliCommand)
    updateCliCommand()

    const copyButton = proposalModal.find('.copy-button')
    if( ClipboardJS.isSupported() ) {
      const clipboard = new ClipboardJS(
        copyButton.get(0),
        { text: (() => proposalModal.find('pre.cli-command').text()),
          container: proposalModal.get(0) }
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
