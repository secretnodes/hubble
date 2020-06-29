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

      await this.ledger.setupConnection();

      const setupError = null;
      if( setupError ) {
        this.modal.find('.delegation-step').hide()
        this.modal.find('.step-error')
          .find('.delegation-error').text(setupError == "" ? "Unknown error." : setupError)
          .end().show()
        return
      }

      this.modal.find('.step-setup').hide()

      if( _.includes( App.config.existingDelegators, this.ledger.publicAddress ) ) {
        const rewardsBalance = this.ledger.scale(this.ledger.txContext.rewards_for_validator[0].amount);
        this.modal.find('.step-choice')
          .find('.reward-balance').text( `${rewardsBalance} ${App.config.denom}` ).end()
          .show()
        if( this.ledger.accountBalance == 0 ) {
          this.modal.find('.choice-redelegate').attr('disabled', 'disabled')
        }

        this.modal.find('.choice-redelegate').click( () => {
          this.modal.find('.step-choice').hide()
          this.withdrawal()
        } )
        this.modal.find('.choice-new-delegation').click( async () => {
          this.modal.find('.step-choice').hide()
          this.newDelegation();
        } )
      }
      else {
        this.newDelegation();
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
    this.modal.find('.modal-dialog').addClass('modal-lg')
    this.modal.find('.step-new-delegation')
      .find('.account-balance').text( `${this.ledger.scaledBalance} ${App.config.denom}` ).end()
      .find('.account-address').html( this.ledger.publicAddress ).end()
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

      let txObject = Ledger.createDelegate(this.ledger.txContext, App.config.validatorOperatorAddress, this.delegationAmount.toString());
      let sign = await this.ledger.buildAndSign(this.ledger.txContext, txObject, this.DELEGATION_GAS_WANTED.toString());

      this.modal.find('.transaction-json').text(
        JSON.stringify( txObject, undefined, 2 )
      )

      const txSignature = Ledger.applySignature(sign.newTxObject, this.ledger.txContext, sign.sigArray);

      let broadcastError = null
      if( txSignature ) {
        const broadcastResult = await this.ledger.broadcastTransaction( txSignature )
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

  async withdrawal() {
    this.modal.find('.modal-dialog').removeClass('modal-lg')
    this.modal.find('.step-confirm').show()

    const txObject = Ledger.createSkeleton(this.ledger.txContext, this.withdrawalTransactionObject());
    let sign = await this.ledger.buildAndSign(this.ledger.txContext, txObject, this.DELEGATION_GAS_WANTED.toString());

    this.modal.find('.transaction-json').text(
      JSON.stringify( txObject, undefined, 2 )
    )

    const txSignature = Ledger.applySignature(sign.newTxObject, this.ledger.txContext, sign.sigArray);

    let broadcastError = null
    if( txSignature ) {
      console.log(txSignature);
      const broadcastResult = await this.ledger.broadcastTransaction( txSignature )
      console.log(broadcastResult);
      if( broadcastResult.ok ) {
        this.modal.find('.step-confirm').hide()
        this.modal.find('.view-transaction').attr( 'href', App.config.viewTxPath.replace('TRANSACTION_HASH', broadcastResult.txhash) )
        this.modal.find('.step-complete').show()
        ga('send', 'event', 'delegation', 'completed')
        return
      }
      else {
        broadcastError = broadcastResult.error_message
      }
    }
    this.modal.find('.step-confirm').hide()
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

  withdrawalTransactionObject() {
    return [
      {
        type: 'cosmos-sdk/MsgWithdrawDelegationReward',
        value: {
          delegator_address: this.publicAddress,
          validator_address: App.config.validatorOperatorAddress
        }
      }
    ]
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
    return (this.ledger.accountBalance - this.delegationTransactionFee(false)) / App.config.remoteScaleFactor
  }

  checkDelegationAmount( amount ) {
    return amount > 0 && amount <= this.maxDelegation()
  }

  setDelegationAmount( amount ) {
    this.delegationAmount = amount * App.config.remoteScaleFactor
  }
}

App.Common.DelegationModal = DelegationModal
