import { DEFAULT_MEMO, Ledger } from './ledger.js';

class GovProposalVoteModal {
  constructor( el ) {
    this.GAS_WANTED = 150000
    this.GAS_PRICE = 0.025
    this.MEMO = 'Submit, deposit and vote on proposals with Puzzle - https://puzzle.secretnodes.org'

    this.modal = el
    this.reset()
    this.modal.on( 'hidden.bs.modal', () => this.reset() )

    let triggeredGAEvent =  false
    this.modal.on( 'shown.bs.modal', async () => {
      this.reset()

      if( !triggeredGAEvent ) { ga('send', 'event', 'gov-proposal-vote', 'started') }

      this.ledger = new Ledger({ testModeAllowed: false })

      await this.ledger.setupConnection();
      const setupError = null;

      if( setupError ) {
        this.modal.find('.proposal-step').hide()
        this.modal.find('.step-error')
          .find('.proposal-error').text(setupError == "" ? "Unknown error." : setupError)
          .end().show()
        return
      }

      this.modal.find('.step-setup').hide()

      if( this.ledger.accountBalance < (this.transactionFee() * 2) ) {
        ga('send', 'event', 'gov-proposal-vote', 'failed')
        this.modal.find('.proposal-step').hide()
        this.modal.find('.step-error')
          .find('.proposal-error').text(this.ledger.signError || broadcastError || "Unknown error")
          .end().show()
        return
      }

      this.modal.find('.modal-dialog').addClass('modal-lg')
      this.modal.find('.step-proposal-vote')
        .find('.account-balance').text( `${this.ledger.accountBalance} ${App.config.denom}` ).end()
        .find('.account-address').html( this.ledger.publicAddress ).end()
        .find('.transaction-fee').text( `${this.transactionFee()} ${App.config.denom}` ).end()
        .show()

      this.modal.find('.vote-option input').on( 'change', ( e ) => {
        const input = $(e.currentTarget)
        this.voteOption = input.val()
        input.parents('.vote-option').addClass('selected').siblings('.vote-option').removeClass('selected')
        this.modal.find('.proposal-form').data( 'disabled', false )
        this.modal.find('.submit-proposal-vote').removeAttr( 'disabled' )
      } )

      this.modal.find('.proposal-form').submit( async ( e ) => {
        e.preventDefault()

        if( $(e.currentTarget).data('disabled') ) { return }

        this.modal.find('.proposal-step').hide()
        this.modal.find('.modal-dialog').removeClass('modal-lg')
        this.modal.find('.step-confirm').show()

        const txObject = Ledger.createVote(this.ledger.txContext, App.config.proposalId.toString(), this.voteOption);
        let sign = await this.ledger.buildAndSign(this.ledger.txContext, txObject, this.GAS_WANTED.toString());

        this.modal.find('.transaction-json').text(
          JSON.stringify( txObject, undefined, 2 )
        )

        const txSignature = Ledger.applySignature(sign.newTxObject, this.ledger.txContext, sign.sigArray);
        let broadcastError = null
        if( txSignature ) {
          const broadcastResult = await this.ledger.broadcastTransaction( txSignature )

          if( broadcastResult.ok ) {
            this.modal.find('.proposal-step').hide()
            this.modal.find('.view-transaction').attr( 'href', App.config.viewTxPath.replace('TRANSACTION_HASH', broadcastResult.txhash) )
            this.modal.find('.step-complete').show()
            ga('send', 'event', 'gov-proposal-vote', 'completed')
            return
          }
          else {
            broadcastError = broadcastResult.error_message
          }
        }

        ga('send', 'event', 'gov-proposal-vote', 'failed')
        this.modal.find('.proposal-step').hide()
        this.modal.find('.step-error')
          .find('.proposal-error').text(this.ledger.signError || broadcastError || "Unknown error")
          .end().show()
      } )

      this.modal.find('.show-transaction-json').click( ( e ) => {
        $(e.currentTarget).hide()
        this.modal.find('.transaction-json-container').show()
      } )
    } )
  }

  reset() {
    this.voteOption = null
    this.modal.find('.modal-dialog').removeClass('modal-lg')
    this.modal.find('.proposal-step').hide()
    this.modal.find('.step-setup').show()
    this.modal.find('.proposal-form').off('submit').data( 'disabled', true )
    this.modal.find('.submit-proposal-vote').attr( 'disabled', 'disabled' )
    this.modal.find('.show-transaction-json').off('click').show()
    this.modal.find('.transaction-json-container').hide()
    this.modal.find('.view-transaction').attr( 'href', '' )
  }

  transactionFee( scale=true ) {
    return (this.GAS_WANTED * this.GAS_PRICE) / (scale ? App.config.remoteScaleFactor : 1)
  }
}

App.Common.GovProposalVoteModal = GovProposalVoteModal
