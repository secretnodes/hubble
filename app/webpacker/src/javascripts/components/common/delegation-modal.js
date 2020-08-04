import { DEFAULT_MEMO, Ledger } from './ledger.js';
import { MathWallet } from './mathwallet.js'
import { Keplr } from './keplr.js'

class DelegationModal {
  constructor( el ) {
    this.DELEGATION_GAS_WANTED = 200000
    this.REDELEGATION_GAS_WANTED = 220000
    this.GAS_PRICE = 0.025
    this.MEMO = 'https://puzzle.report'
    this.modal = el

    this.reset()
    this.modal.on( 'hidden.bs.modal', () => this.reset() )

    let triggeredGAEvent =  false
    this.modal.on( 'shown.bs.modal', async () => {
      this.reset()

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

    if ( !App.config.walletPresent ) {
      await this.wallet.addWallet(App.config.userId, App.config.chainId);
    }
    this.wallet_type = "ledger";
    let button_text = "Sign with Ledger";
    this.modal.find('.submit-delegation').text('Sign with Ledger');
    this.showStepChoice();
  }

  async setupMathwallet() {
    this.modal.find('.step-setup').show()
    this.wallet = new MathWallet();
    await this.wallet.setupConnection();

    if ( !App.config.walletPresent ) {
      await this.wallet.addWallet(App.config.userId, App.config.chainId);
    }
    this.wallet_type = "mathwallet";
    let btn = this.modal.find('.submit-delegation').text("Sign with Mathwallet");
    this.showStepChoice();
  }

  async setupKeplr() {
    this.modal.find('.step-setup').show()
    this.wallet = new Keplr();
    await this.wallet.setupConnection();

    if ( !App.config.walletPresent ) {
      await this.wallet.addWallet(App.config.userId, App.config.chainId);
    }
    this.wallet_type = "keplr";
    let btn = this.modal.find('.submit-delegation').text("Sign with Keplr");
    this.showStepChoice();
  }

  showStepChoice() {
    const setupError = null;
    if( setupError ) {
      this.modal.find('.delegation-step').hide()
      this.modal.find('.step-error')
        .find('.delegation-error').text(setupError == "" ? "Unknown error." : setupError)
        .end().show()
      return
    }

    this.modal.find('.step-setup').hide()

    if( _.includes( App.config.existingDelegators, this.wallet.publicAddress ) ) {
      const rewardsBalance = this.wallet.scale(this.wallet.txContext.rewards_for_validator[0].amount);
      this.modal.find('.step-choice')
        .find('.reward-balance').text( `${rewardsBalance} ${App.config.denom}` ).end()
        .show()
      if( this.wallet.accountBalance == 0 ) {
        this.modal.find('.choice-redelegate').attr('disabled', 'disabled')
      }

      this.modal.find('.choice-redelegate').click( async () => {
        this.modal.find('.step-choice').hide()
        this.reDelegation();
      } )
      this.modal.find('.choice-withdraw').click( () => {
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
  }

  reset() {
    this.modal.find('.modal-dialog').removeClass('modal-lg')
    this.modal.find('.delegation-step').hide()
    this.modal.find('.step-choose-wallet').show()
    this.modal.find('.delegation-amount').val('').off('input')
    this.modal.find('.set-max').off('click')
    this.modal.find('.delegation-form').off('submit').data( 'disabled', true )
    this.modal.find('.submit-delegation').attr( 'disabled', 'disabled' )
    this.modal.find('.choice-redelegate').removeAttr('disabled')
    this.modal.find('.show-transaction-json').off('click').show()
    this.modal.find('.transaction-json-container').hide()
    this.modal.find('.amount-error').hide()
    this.modal.find('.amount-warning').hide()
    this.modal.find('.ledger-instructions').hide()
    this.modal.find('.view-transaction').attr( 'href', '' )
  }

  newDelegation(response) {
    this.modal.find('.modal-dialog').addClass('modal-lg')
    this.modal.find('.step-new-delegation')
      .find('.account-balance').text( `${this.wallet.scaledBalance} ${App.config.denom}` ).end()
      .find('.account-address').html( this.wallet.publicAddress ).end()
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

      let broadcastError = null;
      
      if (this.wallet_type == "keplr") {
        const msg = await this.wallet.sendDelegationMsg(
          this.wallet.publicAddress,
          App.config.validatorOperatorAddress,
          this.delegationAmount,
          this.DELEGATION_GAS_WANTED,
          this.delegationTransactionFee(false),
          this.MEMO);

        if (msg.deliverTx.code == 0) {
          this.modal.find('.delegation-step').hide()
          this.modal.find('.view-transaction').hide()
          this.modal.find('.step-complete').show()
          ga('send', 'event', 'delegation', 'completed')
          return
        }
        else {
          let broadcastError = msg.deliverTx.log
        }

      } else {
        if (this.wallet_type == "ledger") {
          let txObject = Ledger.createSkeleton(this.wallet.txContext, this.delegationTransactionObject());
          let sign = await this.wallet.buildAndSign(this.wallet.txContext, txObject, this.DELEGATION_GAS_WANTED.toString());
  
          this.modal.find('.transaction-json').text(
            JSON.stringify( txObject, undefined, 2 )
          )
  
          this.txSignature = Ledger.applySignature(sign.newTxObject, this.wallet.txContext, sign.sigArray);
        } else if (this.wallet_type == "mathwallet") {
          let txObject = MathWallet.createTx(
            this.wallet.txContext,
            this.delegationTransactionObject(),
            this.DELEGATION_GAS_WANTED.toString()
          );
  
  
          this.txSignature = await this.wallet.buildAndSign(txObject);
        }
  
        if( this.txSignature ) {
          const broadcastResult = await this.wallet.broadcastTransaction( this.txSignature )
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
      }
      ga('send', 'event', 'delegation', 'failed')
      this.modal.find('.delegation-step').hide()
      this.modal.find('.step-error')
        .find('.delegation-error').text(broadcastError || this.wallet.signError || "Unknown error")
        .end().show()
    } )
  }

  async withdrawal() {
    this.modal.find('.modal-dialog').removeClass('modal-lg')
    this.modal.find('.step-confirm').show()

    let broadcastError = null;

    if (this.wallet_type == "keplr") {
      const msg = await this.wallet.sendWithdrawalMsg(
        this.wallet.publicAddress,
        App.config.validatorOperatorAddress,
        this.DELEGATION_GAS_WANTED,
        this.delegationTransactionFee(false),
        this.MEMO);

      if (msg.deliverTx.code == 0) {
        this.modal.find('.delegation-step').hide()
        this.modal.find('.view-transaction').hide()
        this.modal.find('.step-complete').show()
        ga('send', 'event', 'delegation', 'completed')
        return
      }
      else {
        let broadcastError = msg.deliverTx.log
      }

    } else {
      if (this.wallet_type == "ledger") {
        let txObject = Ledger.createSkeleton(this.wallet.txContext, this.withdrawalTransactionObject());
        let sign = await this.wallet.buildAndSign(this.wallet.txContext, txObject, this.DELEGATION_GAS_WANTED.toString());

        this.modal.find('.transaction-json').text(
          JSON.stringify( txObject, undefined, 2 )
        )

        this.txSignature = Ledger.applySignature(sign.newTxObject, this.wallet.txContext, sign.sigArray);
      } else {
        let txObject = MathWallet.createTx(
          this.wallet.txContext,
          this.withdrawalTransactionObject(),
          this.DELEGATION_GAS_WANTED.toString()
        );

        this.txSignature = await this.wallet.buildAndSign(txObject);
      }

      if( this.txSignature ) {
        const broadcastResult = await this.wallet.broadcastTransaction( this.txSignature )
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
    }
    this.modal.find('.step-confirm').hide()
    ga('send', 'event', 'delegation', 'failed')
    this.modal.find('.step-error')
      .find('.delegation-error').text(broadcastError || this.wallet.signError || "Unknown error")
      .end().show()
  }

  reDelegation() {
    let delegation_index = this.wallet.txContext.delegations.findIndex(v => v.validator_address == App.config.validatorOperatorAddress );
    this.max_redelegation_amount = this.wallet.txContext.delegations[delegation_index]['balance']['amount'];
    this.modal.find('.modal-dialog').addClass('modal-lg')
    this.modal.find('.step-redelegation')
      .find('.account-balance').text( `${this.maxRedelegation()} ${App.config.denom}` ).end()
      .find('.account-address').html( this.wallet.publicAddress ).end()
      .find('.transaction-fee').text( `${this.redelegationTransactionFee()} ${App.config.denom}` ).end()
      .show()

    this.modal.find('.set-max').click( ( e ) => {
      e.preventDefault()
      this.modal.find('.delegation-amount').val( this.maxRedelegation() ).trigger('set-to-max')
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

      this.modal.find('.transaction-total').text( `${this.redelegationTotal(amount)} ${App.config.denom}` )

      if( !this.checkRedelegationAmount( amount ) ) {
        this.modal.find('.amount-warning').hide()
        this.setDelegationAmount( null )
        const msg = amount == 0 ?
          `You can't delegate <tt>0 ${App.config.denom}</tt>...` :
          `The amount to delegate must take transaction fees into account.<br/><b>Max: <tt class='text-md'>${this.maxRedelegation()} ${App.config.denom}</tt></b>`
        this.modal.find('.amount-error').html(msg).show()
        this.modal.find('.submit-delegation').attr( 'disabled', 'disabled' )
      }
      else {
        if( amount == this.maxRedelegation() ) {
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

      this.validator_dst_address = this.modal.find('.to-validator option:selected').val();
      let broadcastError = null;

      if (this.wallet_type == "keplr") {
        const msg = await this.wallet.sendRedelegationMsg(
          this.wallet.publicAddress,
          App.config.validatorOperatorAddress,
          this.validator_dst_address,
          this.delegationAmount,
          this.REDELEGATION_GAS_WANTED,
          this.redelegationTransactionFee(false),
          this.MEMO);

        if (msg.deliverTx.code == 0) {
          this.modal.find('.delegation-step').hide()
          this.modal.find('.view-transaction').hide()
          this.modal.find('.step-complete').show()
          ga('send', 'event', 'delegation', 'completed')
          return
        }
        else {
          broadcastError = msg.deliverTx.log
        }

      } else {

        if (this.wallet_type == "ledger") {
          let txObject = Ledger.createSkeleton(this.wallet.txContext, this.redelegationTransactionObject());
          let sign = await this.wallet.buildAndSign(this.wallet.txContext, txObject, this.REDELEGATION_GAS_WANTED.toString());

          this.modal.find('.transaction-json').text(
            JSON.stringify( txObject, undefined, 2 )
          )

          this.txSignature = Ledger.applySignature(sign.newTxObject, this.wallet.txContext, sign.sigArray);
        } else {
          let txObject = MathWallet.createTx(
            this.wallet.txContext,
            this.redelegationTransactionObject(),
            this.REDELEGATION_GAS_WANTED.toString()
          );


          this.txSignature = await this.wallet.buildAndSign(txObject);
        }

        if( this.txSignature ) {
          const broadcastResult = await this.wallet.broadcastTransaction( this.txSignature )
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
      }

      ga('send', 'event', 'delegation', 'failed')
      this.modal.find('.delegation-step').hide()
      this.modal.find('.step-error')
        .find('.delegation-error').text(broadcastError || this.wallet.signError || "Unknown error")
        .end().show()
    } )
  }

  delegationTransactionObject() {
    return [
      {
        type: 'cosmos-sdk/MsgDelegate',
        value: {
          amount: { amount: this.delegationAmount.toString(), denom: App.config.remoteDenom },
          delegator_address: this.wallet.publicAddress,
          validator_address: App.config.validatorOperatorAddress
        }
      }
    ]
  }

  withdrawalTransactionObject() {
    return [
      {
        type: 'cosmos-sdk/MsgWithdrawDelegationReward',
        value: {
          delegator_address: this.wallet.publicAddress,
          validator_address: App.config.validatorOperatorAddress
        }
      }
    ]
  }

  redelegationTransactionObject() {
    return [
      {
        type: 'cosmos-sdk/MsgBeginRedelegate',
        value: {
          amount: { amount: this.delegationAmount.toString(), denom: App.config.remoteDenom },
          delegator_address: this.wallet.publicAddress,
          validator_dst_address: this.validator_dst_address,
          validator_src_address: App.config.validatorOperatorAddress
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

  redelegationTotal( amount ) {
    return ((amount * App.config.remoteScaleFactor) + this.redelegationTransactionFee(false)) / App.config.remoteScaleFactor
  }

  maxDelegation() {
    return (this.wallet.accountBalance - this.delegationTransactionFee(false)) / App.config.remoteScaleFactor
  }

  maxRedelegation() {
    return (this.max_redelegation_amount) / App.config.remoteScaleFactor
  }

  checkDelegationAmount( amount ) {
    return amount > 0 && amount <= this.maxDelegation()
  }

  checkRedelegationAmount( amount ) {
    return amount > 0 && amount <= this.maxRedelegation()
  }

  setDelegationAmount( amount ) {
    this.delegationAmount = amount * App.config.remoteScaleFactor
  }
}

App.Common.DelegationModal = DelegationModal
