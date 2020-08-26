import { DEFAULT_MEMO, Ledger } from './ledger.js';
import { MathWallet } from './mathwallet.js';
import { Keplr } from './keplr.js'

class GovProposalVoteModal {
  constructor( el ) {
    this.GAS_WANTED = 150000
    this.GAS_PRICE = 0.025
    this.MEMO = 'https://puzzle.report'

    this.modal = el
    this.reset()
    this.modal.on( 'hidden.bs.modal', () => this.reset() )

    let triggeredGAEvent =  false
    this.modal.on( 'shown.bs.modal', async () => {
      this.reset()

      if( !triggeredGAEvent ) { ga('send', 'event', 'gov-proposal-vote', 'started') }

      this.modal.find('.choice-ledger').click( async () => {
        this.modal.find('.step-choose-wallet').hide()
        this.setupLedger();
      } )

      this.modal.find('.choice-mathwallet').click( async () => {
        this.modal.find('.step-choose-wallet').hide()
        this.setupMathwallet();
      } )

      this.modal.find('.choice-keplr').click( async () => {
        this.modal.find('.step-choose-wallet').hide()
        this.setupKeplr();
      } )
    } )
  }

  async setupLedger() {
    this.modal.find('.step-setup').show()
    this.modal.find('.ledger-instructions').show()
    this.wallet = new Ledger({ testModeAllowed: false });
    await this.wallet.setupConnection();

    try {
      await this.wallet.addWallet(App.config.userId, App.config.chainId);
    } catch (error) {
      console.log(error);
    }

    this.wallet_type = "ledger";
    this.modal.find('.submit-proposal-deposit').text('Sign with Ledger');
    this.modal.find('.submit-proposal-vote').text('Sign with Ledger');
    this.showStepChoice();
  }

  async setupMathwallet() {
    this.modal.find('.step-setup').show()
    this.wallet = new MathWallet();
    await this.wallet.setupConnection();

    try {
      await this.wallet.addWallet(App.config.userId, App.config.chainId);
    } catch (error) {
      console.log(error);
    }

    this.wallet_type = "mathwallet";
    this.modal.find('.submit-proposal-deposit').text('Sign with Mathwallet');
    this.modal.find('.submit-proposal-vote').text('Sign with Mathwallet');
    this.showStepChoice();
  }

  async setupKeplr() {
    this.modal.find('.step-setup').show()
    this.wallet = new Keplr();
    await this.wallet.setupConnection();

    try {
      await this.wallet.addWallet(App.config.userId, App.config.chainId);
    } catch (error) {
      console.log(error);
    }

    this.wallet_type = "keplr";
    let btn = this.modal.find('.submit-proposal-deposit').text("Sign with Keplr");
    this.modal.find('.submit-proposal-vote').text("Sign with Keplr");
    this.showStepChoice();
  }

  showStepChoice() {
    const setupError = null;

    if( setupError ) {
      this.modal.find('.proposal-step').hide()
      this.modal.find('.step-error')
        .find('.proposal-error').text(setupError == "" ? "Unknown error." : setupError)
        .end().show()
      return
    }

    this.modal.find('.step-setup').hide()

    if( this.wallet.accountBalance < (this.transactionFee() * 2) ) {
      ga('send', 'event', 'gov-proposal-vote', 'failed')
      this.modal.find('.proposal-step').hide()
      this.modal.find('.step-error')
        .find('.proposal-error').text(this.wallet.signError || broadcastError || "Unknown error")
        .end().show()
      return
    }

    this.modal.find('.modal-dialog').addClass('modal-lg')
    this.modal.find('.step-proposal-vote')
      .find('.account-balance').text( `${this.wallet.accountBalance} ${App.config.denom}` ).end()
      .find('.account-address').html( this.wallet.publicAddress ).end()
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

      let broadcastError = null;
      
        if (this.wallet_type == "keplr") {
          const msg = await this.wallet.sendVoteMsg(
            App.config.proposalId,
            this.wallet.publicAddress,
            this.voteOption,
            this.GAS_WANTED,
            this.transactionFee(false),
            this.MEMO);

          if (msg.deliverTx.code == 0) {
            let hash = Buffer.from(msg.hash).toString('hex');
            this.modal.find('.delegation-step').hide()
            this.modal.find('.view-transaction').attr( 'href', App.config.viewTxPath.replace('TRANSACTION_HASH', hash) )
            this.modal.find('.step-complete').show()
            ga('send', 'event', 'delegation', 'completed')
            return
          }
          else {
            broadcastError = msg.deliverTx.log
          }

        } else { 

        if (this.wallet_type == "ledger") {
          const txObject = Ledger.createSkeleton(this.wallet.txContext, this.voteTransactionObject());
          let sign = await this.wallet.buildAndSign(this.wallet.txContext, txObject, this.GAS_WANTED.toString());

          this.modal.find('.transaction-json').text(
            JSON.stringify( txObject, undefined, 2 )
          )

          this.txSignature = Ledger.applySignature(sign.newTxObject, this.wallet.txContext, sign.sigArray);
        } else {
          let txObject = MathWallet.createTx(
            this.wallet.txContext,
            this.voteTransactionObject(),
            this.GAS_WANTED.toString()
          );

          this.txSignature = await this.wallet.buildAndSign(txObject);
        }

        if( this.txSignature ) {
          const broadcastResult = await this.wallet.broadcastTransaction( this.txSignature )

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
      }

      ga('send', 'event', 'gov-proposal-vote', 'failed')
      this.modal.find('.proposal-step').hide()
      this.modal.find('.step-error')
        .find('.proposal-error').text(this.wallet.signError || broadcastError || "Unknown error")
        .end().show()
    } )

    this.modal.find('.show-transaction-json').click( ( e ) => {
      $(e.currentTarget).hide()
      this.modal.find('.transaction-json-container').show()
    } )
  }

  reset() {
    this.voteOption = null
    this.modal.find('.modal-dialog').removeClass('modal-lg')
    this.modal.find('.proposal-step').hide()
    this.modal.find('.step-choose-wallet').show()
    this.modal.find('.proposal-form').off('submit').data( 'disabled', true )
    this.modal.find('.submit-proposal-vote').attr( 'disabled', 'disabled' )
    this.modal.find('.show-transaction-json').off('click').show()
    this.modal.find('.transaction-json-container').hide()
    this.modal.find('.ledger-instructions').hide()
    this.modal.find('.view-transaction').attr( 'href', '' )
  }

  transactionFee( scale=true ) {
    return (this.GAS_WANTED * this.GAS_PRICE) / (scale ? App.config.remoteScaleFactor : 1)
  }

  voteTransactionObject() {
    return [
        {
          type: 'cosmos-sdk/MsgVote',
          value: {
            option: this.voteOption,
            proposal_id: App.config.proposalId.toString(),
            voter: this.wallet.publicAddress,
          },
        }
      ]
  }
}

App.Common.GovProposalVoteModal = GovProposalVoteModal
