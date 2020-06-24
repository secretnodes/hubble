import { DEFAULT_MEMO, Ledger } from './ledger.js';

class DelegationModal {
  constructor( el ) {
    this.DELEGATION_GAS_WANTED = 194854
    this.REDELEGATION_GAS_WANTED = 200000
    this.GAS_PRICE = 0.025
    this.MEMO = 'Delegate to your favorite validator with Puzzle - https://puzzle.report'
    this.modal = el

    this.reset()
    this.modal.on( 'hidden.bs.modal', () => this.reset() )

    let triggeredGAEvent =  false
    this.modal.on( 'shown.bs.modal', async () => {
      this.reset()

      if( !triggeredGAEvent ) { ga('send', 'event', 'delegation', 'started') }

      this.ledger = new Ledger({ testModeAllowed: false });

      const publicAddress = await this.ledger.getCosmosAddress();
      this.pubKey = publicAddress.pubKey
      this.publicAddress = publicAddress.address;

      const setupError = null;
      if( setupError ) {
        this.modal.find('.delegation-step').hide()
        this.modal.find('.step-error')
          .find('.delegation-error').text(setupError == "" ? "Unknown error." : setupError)
          .end().show()
        return
      }

      this.modal.find('.step-setup').hide()

      if( _.includes( App.config.existingDelegators, this.ledger.getCosmosAddress() ) ) {
        this.modal.find('.step-choice')
          .find('.reward-balance').text( `${this.rewardsBalance()} ${App.config.denom}` ).end()
          .show()
        if( this.rewardsBalance() == 0 ) {
          this.modal.find('.choice-redelegate').attr('disabled', 'disabled')
        }

        this.modal.find('.choice-redelegate').click( () => {
          this.modal.find('.step-choice').hide()
          this.redelegation()
        } )
        this.modal.find('.choice-new-delegation').click( async () => {
          this.modal.find('.step-choice').hide()
          this.getAccountBalance(publicAddress.address)
            .then(response=> this.newDelegation(response))
        } )
      }
      else {
        this.getAccountBalance(publicAddress.address)
          .then(response=> this.newDelegation(response))
      }

      this.modal.find('.show-transaction-json').click( ( e ) => {
        $(e.currentTarget).hide()
        this.modal.find('.transaction-json-container').show()
      } )
    } )
  }

  reset() {
    this.modal.find('.modal-dialog').removeClass('modal-lg')
    this.modal.find('.delegation-step').hide()
    this.modal.find('.step-setup').show()
    this.modal.find('.delegation-amount').val('').off('input')
    this.modal.find('.set-max').off('click')
    this.modal.find('.delegation-form').off('submit').data( 'disabled', true )
    this.modal.find('.submit-delegation').attr( 'disabled', 'disabled' )
    this.modal.find('.choice-redelegate').removeAttr('disabled')
    this.modal.find('.show-transaction-json').off('click').show()
    this.modal.find('.transaction-json-container').hide()
    this.modal.find('.amount-error').hide()
    this.modal.find('.amount-warning').hide()
    this.modal.find('.view-transaction').attr( 'href', '' )
  }

  newDelegation(response) {

    this.balance = this.formatBalance(response)
    const scaledBalance = this.balance / App.config.remoteScaleFactor;
    this.modal.find('.modal-dialog').addClass('modal-lg')
    this.modal.find('.step-new-delegation')
      .find('.account-balance').text( `${scaledBalance} ${App.config.denom}` ).end()
      .find('.account-address').html( this.publicAddress ).end()
      .find('.transaction-fee').text( `${this.delegationTransactionFee()} ${App.config.denom}` ).end()
      .show()

    this.modal.find('.set-max').click( ( e ) => {
      e.preventDefault()
      this.modal.find('.delegation-amount').val( this.maxDelegation() ).trigger('set-to-max')
    } )

    this.modal.find('.delegation-amount').on( 'input set-to-max', ( e ) => {
      const amount = parseFloat( $(e.currentTarget).val() )
      if( isNaN( amount ) ) {
        this.modal.find('.amount-warning').hide()
        this.modal.find('.amount-error').hide()
        this.modal.find('.delegation-form').data( 'disabled', true )
        this.modal.find('.submit-delegation').attr( 'disabled', 'disabled' )
        this.modal.find('.transaction-total').html( '&mdash;' )
        return
      }

      this.modal.find('.transaction-total').text( `${this.delegationTotal(amount)} ${App.config.denom}` )

      if( !this.checkDelegationAmount( amount ) ) {
        this.modal.find('.amount-warning').hide()
        this.setDelegationAmount( null )
        const msg = amount == 0 ?
          `You can't delegate <tt>0 ${App.config.denom}</tt>...` :
          `The amount to delegate must take transaction fees into account.<br/><b>Max: <tt class='text-md'>${this.maxDelegation()} ${App.config.denom}</tt></b>`
        this.modal.find('.amount-error').html(msg).show()
        this.modal.find('.submit-delegation').attr( 'disabled', 'disabled' )
      }
      else {
        if( amount == this.maxDelegation() ) {
          const msg = `It is recommended to leave some ${App.config.denom} in your account to pay fees on future transactions!`
          this.modal.find('.amount-warning').html(msg).show()
        }
        else {
          this.modal.find('.amount-warning').hide()
        }
        this.setDelegationAmount( amount )
        this.modal.find('.amount-error').hide()
        this.modal.find('.delegation-form').data( 'disabled', false )
        this.modal.find('.submit-delegation').removeAttr( 'disabled' )
      }
    } )

    this.modal.find('.delegation-form').submit( async ( e ) => {
      e.preventDefault()

      if( $(e.currentTarget).data('disabled') ) { return }

      this.modal.find('.delegation-step').hide()
      this.modal.find('.modal-dialog').removeClass('modal-lg')
      this.modal.find('.step-confirm').show()
      this.txContext = await this.setTxContext();
      this.txContext.chain_id = 'secret-1';
      this.txContext.public_key = Buffer.from(this.pubKey).toString('base64');

      let txObject = Ledger.createDelegate(this.txContext, App.config.validatorOperatorAddress, this.delegationAmount.toString());
      Ledger.applyGas(txObject, this.DELEGATION_GAS_WANTED.toString());
      const newTxObject = this.modifyTxObject(txObject);
      const bytes = Ledger.getBytesToSign(txObject, this.txContext);
      const sigArray = await this.ledger.sign(bytes);

      this.modal.find('.transaction-json').text(
        JSON.stringify( txObject, undefined, 2 )
      )

      const txSignature = Ledger.applySignature(newTxObject, this.txContext, sigArray);

      let broadcastError = null
      if( txSignature ) {
        const broadcastResult = await this.broadcastTransaction( txSignature )
        if( broadcastResult.ok ) {
          this.modal.find('.delegation-step').hide()
          this.modal.find('.view-transaction').attr( 'href', App.config.viewTxPath.replace('TRANSACTION_HASH', broadcastResult.txhash) )
          this.modal.find('.step-complete').show()
          ga('send', 'event', 'delegation', 'completed')
          return
        }
        else {
          broadcastError = broadcastResult.error_message
        }
      }

      ga('send', 'event', 'delegation', 'failed')
      this.modal.find('.delegation-step').hide()
      this.modal.find('.step-error')
        .find('.delegation-error').text("this.ledger.signError" || broadcastError || "Unknown error")
        .end().show()
    } )
  }

  async redelegation() {
    this.modal.find('.modal-dialog').removeClass('modal-lg')
    this.modal.find('.step-confirm').show()

    const txObject = this.redelegationTransactionObject()

    this.modal.find('.transaction-json').text(
      JSON.stringify( txObject, undefined, 2 )
    )

    const txPayload = await this.ledger.generateTransaction( txObject )
    let broadcastError = null
    if( txPayload ) {
      const broadcastResult = await this.ledger.broadcastTransaction( txPayload )
      if( broadcastResult.ok ) {
        this.modal.find('.view-transaction').attr( 'href', App.config.viewTxPath.replace('TRANSACTION_HASH', broadcastResult.txhash) )
        this.modal.find('.step-complete').show()
        ga('send', 'event', 'delegation', 'completed')
        return
      }
      else {
        broadcastError = broadcastResult.error_message
      }
    }

    ga('send', 'event', 'delegation', 'failed')
    this.modal.find('.step-error')
      .find('.delegation-error').text(this.ledger.signError || broadcastError || "Unknown error")
      .end().show()
  }

  delegationTransactionObject() {
    return {
      msg: [
        {
          type: 'cosmos-sdk/MsgDelegate',
          value: {
            delegator_address: this.publicAddress,
            validator_address: App.config.validatorOperatorAddress,
            amount: { denom: App.config.remoteDenom, amount: this.delegationAmount.toString() }
          }
        }
      ],
      fee: {
        amount: [
          {
            denom: App.config.remoteDenom,
            amount: this.delegationTransactionFee( false ).toString()
          }
        ],
        gas: this.DELEGATION_GAS_WANTED.toString()
      },
      signatures: null,
      memo: this.MEMO
    }
  }

  redelegationTransactionObject() {
    return {
      msg: [
        {
          type: 'cosmos-sdk/MsgWithdrawDelegationReward',
          value: {
            delegator_address: this.ledger.accountInfo.value.address,
            validator_address: App.config.validatorOperatorAddress
          }
        },
        {
          type: 'cosmos-sdk/MsgDelegate',
          value: {
            delegator_address: this.ledger.accountInfo.value.address,
            validator_address: App.config.validatorOperatorAddress,
            amount: { denom: App.config.remoteDenom, amount: this.rewardsBalance(false).toString() }
          }
        }
      ],
      fee: {
        amount: [
          {
            denom: App.config.remoteDenom,
            amount: this.redelegationTransactionFee( false ).toString()
          }
        ],
        gas: this.REDELEGATION_GAS_WANTED.toString()
      },
      signatures: null,
      memo: this.MEMO
    }
  }

  rewardsBalance( scale=true ) {
    const foundByDenom = _.find(
      this.ledger.accountInfo.rewards_for_validator,
      coin => coin.denom == App.config.remoteDenom
    )

    if( !foundByDenom ) { return 0 }
    return Math.floor(foundByDenom.amount) / (scale ? App.config.remoteScaleFactor : 1)
  }

  delegationTransactionFee( scale=true ) {
    return (this.DELEGATION_GAS_WANTED * this.GAS_PRICE) / (scale ? App.config.remoteScaleFactor : 1)
  }

  redelegationTransactionFee( scale=true ) {
    return (this.REDELEGATION_GAS_WANTED * this.GAS_PRICE) / (scale ? App.config.remoteScaleFactor : 1)
  }

  delegationTotal( amount ) {
    return ((amount * App.config.remoteScaleFactor) + this.delegationTransactionFee(false)) / App.config.remoteScaleFactor
  }

  maxDelegation() {
    return (this.balance - this.delegationTransactionFee(false)) / App.config.remoteScaleFactor
  }

  checkDelegationAmount( amount ) {
    return amount > 0 && amount <= this.maxDelegation()
  }

  setDelegationAmount( amount ) {
    this.delegationAmount = amount * App.config.remoteScaleFactor
  }

  async getAccountBalance( ) {
    return fetch('/api/v1/account_balance?chain_id=1&address=' + this.publicAddress)
      .then(response => {if (response.status == 200) {
        return response.json()
      } else {
        throw new Error(res.status);
      }});
  }

  formatBalance(response) {
    if (response['balance'][0]['denom'] == 'uscrt') {
      return response['balance'][0]['amount'];
    }
  }

  async setTxContext( ) {
    let url = '/api/v1/account_info?chain_id=1&address=' + this.publicAddress;
    return fetch(url)
      .then(response => {
        if (response.status == 200) {
          return response.json();
        }
      })
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

  modifyTxObject( txObject ) {
    return txObject['value'];
  }
}

App.Common.DelegationModal = DelegationModal
