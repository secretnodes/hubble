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

      const setupError = null;
      const publicAddress = await this.ledger.getCosmosAddress();
      this.pubKey = publicAddress.pubKey
      this.publicAddress = publicAddress.address;
      this.txContext = this.formatTxContext(await this.setTxContext());
      this.accountBalance = this.txContext.coins[0].amount;
      this.scaledBalance = this.scale(this.accountBalance);

      if( setupError ) {
        this.modal.find('.proposal-step').hide()
        this.modal.find('.step-error')
          .find('.proposal-error').text(setupError == "" ? "Unknown error." : setupError)
          .end().show()
        return
      }

      this.modal.find('.step-setup').hide()

      if( this.accountBalance < (this.transactionFee() * 2) ) {
        ga('send', 'event', 'gov-proposal-vote', 'failed')
        this.modal.find('.proposal-step').hide()
        this.modal.find('.step-error')
          .find('.proposal-error').text(this.ledger.signError || broadcastError || "Unknown error")
          .end().show()
        return
      }

      this.modal.find('.modal-dialog').addClass('modal-lg')
      this.modal.find('.step-proposal-vote')
        .find('.account-balance').text( `${this.accountBalance} ${App.config.denom}` ).end()
        .find('.account-address').html( this.publicAddress ).end()
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

        const txObject = Ledger.createVote(this.txContext, App.config.proposalId.toString(), this.voteOption);
        Ledger.applyGas(txObject, this.GAS_WANTED.toString());
        const newTxObject = this.modifyTxObject(txObject);
        const bytes = Ledger.getBytesToSign(txObject, this.txContext);
        const sigArray = await this.ledger.sign(bytes);

        this.modal.find('.transaction-json').text(
          JSON.stringify( txObject, undefined, 2 )
        )

        const txSignature = Ledger.applySignature(newTxObject, this.txContext, sigArray);
        console.log(txSignature);
        let broadcastError = null
        if( txSignature ) {
          const broadcastResult = await this.broadcastTransaction( txSignature )

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

  voteTransactionObject() {
    return {
      msg: [
        {
          type: 'cosmos-sdk/MsgVote',
          value: {
            proposal_id: App.config.proposalId.toString(),
            voter: this.ledger.publicAddress,
            option: this.voteOption
          }
        }
      ],
      fee: {
        amount: [
          {
            denom: App.config.remoteDenom,
            amount: this.transactionFee( false ).toString()
          }
        ],
        gas: this.GAS_WANTED.toString()
      },
      signatures: null,
      memo: this.MEMO
    }
  }

  transactionFee( scale=true ) {
    return (this.GAS_WANTED * this.GAS_PRICE) / (scale ? App.config.remoteScaleFactor : 1)
  }

  scale ( number ) {
    return Math.round((number / App.config.remoteScaleFactor) * 1000000) / 1000000;
  }

  async setTxContext( ) {
    let url = '/secret/chains/secret-1/accounts/' + this.publicAddress + '?validator=' + App.config.validatorOperatorAddress;
    return fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    })
      .then(response => {
        if (response.status == 200) {
          return response.json();
        }
      })
  }

  formatTxContext( txContext ) {
    let newObject = txContext['value'];
    newObject.rewards_for_validator = txContext['rewards_for_validator'];
    newObject.chain_id = 'secret-1';
    newObject.public_key = Buffer.from(this.pubKey).toString('base64');
    return newObject;
  }

  modifyTxObject( txObject ) {
    return txObject['value'];
  }

  async broadcastTransaction( txPayload ) {
    if( !txPayload ) { return false }

    const response = await fetch( App.config.broadcastTxPath, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': $('meta[name=csrf-token]').attr('content')
      },
      body: JSON.stringify( { payload: txPayload } )
    } )
    const responseData = await response.json()
    return responseData
  }
}

App.Common.GovProposalVoteModal = GovProposalVoteModal
