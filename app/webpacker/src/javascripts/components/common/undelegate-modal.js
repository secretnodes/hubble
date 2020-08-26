import { DEFAULT_MEMO, Ledger } from './ledger.js';
import { MathWallet } from './mathwallet.js'
import { Keplr } from './keplr.js'

class UndelegateModal {
  constructor( el ) {
    this.UNDELEGATE_GAS_WANTED = 200000
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
    })
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
    let button_text = "Sign with Ledger";
    this.modal.find('.submit-undelegate').text('Sign with Ledger');
    this.modal.find('.undelegate-step').hide()
    this.newUndelegate();
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
    let btn = this.modal.find('.submit-undelegate').text("Sign with Mathwallet");
    this.modal.find('.undelegate-step').hide()
    this.newUndelegate();
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
    let btn = this.modal.find('.submit-undelegate').text("Sign with Keplr");
    this.modal.find('.undelegate-step').hide()
    this.newUndelegate();
  }

  reset() {
    this.modal.find('.modal-dialog').removeClass('modal-lg')
    this.modal.find('.undelegate-step').hide()
    this.modal.find('.step-choose-wallet').show()
    this.modal.find('.undelegate-amount').val('').off('input')
    this.modal.find('.set-max').off('click')
    this.modal.find('.undelegate-form').off('submit').data( 'disabled', true )
    this.modal.find('.submit-undelegate').attr( 'disabled', 'disabled' )
    this.modal.find('.choice-undelegate').removeAttr('disabled')
    this.modal.find('.show-transaction-json').off('click').show()
    this.modal.find('.transaction-json-container').hide()
    this.modal.find('.amount-error').hide()
    this.modal.find('.amount-warning').hide()
    this.modal.find('.ledger-instructions').hide()
    this.modal.find('.view-transaction').attr( 'href', '' )
  }

  newUndelegate() {
    this.modal.find('.modal-dialog').addClass('modal-lg')

    this.wallet.txContext.delegations.forEach(element => {
      this.modal.find('.from-validator').append($('<option>', {
        value: element.validator_address,
        text: element.validator_address
      }));
    })

    this.modal.find('.from-validator').on( 'change', ( e ) => {
      this.fromValidatorAddress = $(e.currentTarget).val();
      console.log(this.fromValidatorAddress);
      let delegation_index = this.wallet.txContext.delegations.findIndex(v => v.validator_address == this.fromValidatorAddress );
      this.max_undelegate_amount = this.wallet.txContext.delegations[delegation_index]['balance']['amount'];
      this.modal.find('.account-balance').text( `${this.maxUndelegate()} ${App.config.denom}` ).end()
      this.validateUndelegateForm(e);
    })

    this.modal.find('.step-undelegate')
      .find('.account-balance').text( `${this.maxUndelegate()} ${App.config.denom}` ).end()
      .find('.account-address').html( this.wallet.publicAddress ).end()
      .find('.transaction-fee').text( `${this.undelegateTransactionFee()} ${App.config.denom}` ).end()
      .show()

    this.modal.find('.set-max').click( ( e ) => {
      e.preventDefault()
      this.modal.find('.undelegate-amount').val( this.maxUndelegate() ).trigger('set-to-max')
    } )

    this.modal.find('.undelegate-amount').on( 'input set-to-max', ( e ) => {
      this.validateUndelegateForm(e);
    } )

    this.modal.find('.undelegate-form').submit( async ( e ) => {
      e.preventDefault()

      if( $(e.currentTarget).data('disabled') ) { return }

      this.modal.find('.undelegate-step').hide()
      this.modal.find('.modal-dialog').removeClass('modal-lg')
      this.modal.find('.step-confirm').show()

      this.validator_dst_address = this.modal.find('.to-validator option:selected').val();
      let broadcastError = null;

      if (this.wallet_type == "keplr") {
        const msg = await this.wallet.undelegateMsg(
          this.wallet.publicAddress,
          this.toAddress,
          this.undelegateAmount,
          this.UNDELEGATE_GAS_WANTED,
          this.undelegateTransactionFee(false),
          this.MEMO);

        if (msg.deliverTx.code == 0) {
          let hash = Buffer.from(msg.hash).toString('hex');
          this.modal.find('.undelegate-step').hide()
          this.modal.find('.view-transaction').attr( 'href', App.config.viewTxPath.replace('TRANSACTION_HASH', hash) )
          this.modal.find('.step-complete').show()
          ga('undelegate', 'event', 'send', 'completed')
          return
        }
        else {
          broadcastError = msg.deliverTx.log
        }

      } else {

        if (this.wallet_type == "ledger") {
          let txObject = Ledger.createSkeleton(this.wallet.txContext, this.undelegateTransactionObject());
          let sign = await this.wallet.buildAndSign(this.wallet.txContext, txObject, this.UNDELEGATE_GAS_WANTED.toString());

          this.modal.find('.transaction-json').text(
            JSON.stringify( txObject, undefined, 2 )
          )

          this.txSignature = Ledger.applySignature(sign.newTxObject, this.wallet.txContext, sign.sigArray);
        } else {
          let txObject = MathWallet.createTx(
            this.wallet.txContext,
            this.undelegateTransactionObject(),
            this.UNDELEGATE_GAS_WANTED.toString()
          );


          this.txSignature = await this.wallet.buildAndSign(txObject);
        }

        if( this.txSignature ) {
          const broadcastResult = await this.wallet.broadcastTransaction( this.txSignature )
          console.log(broadcastResult);
          if( broadcastResult.ok ) {
            this.modal.find('.undelegate-step').hide()
            this.modal.find('.view-transaction').attr( 'href', App.config.viewTxPath.replace('TRANSACTION_HASH', broadcastResult.txhash) )
            this.modal.find('.step-complete').show()
            ga('undelegate', 'event', 'send', 'completed')
            return
          }
          else {
            broadcastError = broadcastResult.error_message
          }
        }
      }

      ga('undelegate', 'event', 'send', 'failed')
      this.modal.find('.undelegate-step').hide()

      this.modal.find('.step-error')
        .find('.undelegate-error').text(broadcastError || this.wallet.signError || "Unknown error")
        .end().show()
    } )
  }

  undelegateTransactionObject() {
    return [
      {
        type: 'cosmos-sdk/MsgUndelegate',
        value: {
          amount: { amount: this.undelegateAmount.toString(), denom: App.config.remoteDenom },
          delegator_address: this.wallet.publicAddress,
          validator_address: this.fromValidatorAddress
        }
      }
    ]
  }

  undelegateTransactionFee( scale=true ) {
    return (this.UNDELEGATE_GAS_WANTED * this.GAS_PRICE) / (scale ? App.config.remoteScaleFactor : 1)
  }

  undelegateTotal( amount ) {
    return ((amount * App.config.remoteScaleFactor) + this.undelegateTransactionFee(false)) / App.config.remoteScaleFactor
  }

  maxUndelegate() {
    return (this.max_undelegate_amount) / App.config.remoteScaleFactor
  }

  checkUndelegateAmount( amount ) {
    return amount > 0 && amount <= this.maxUndelegate()
  }

  setUndelegateAmount( amount ) {
    this.undelegateAmount = amount * App.config.remoteScaleFactor
  }

  validateUndelegateForm( e ) {
    const amount = parseFloat( this.modal.find('.undelegate-amount').val() )
    
    if( isNaN( amount ) ) {
      this.modal.find('.amount-warning').hide()
      this.modal.find('.amount-error').hide()
      this.modal.find('.undelegate-form').data( 'disabled', true )
      this.modal.find('.submit-undelegate').attr( 'disabled', 'disabled' )
      this.modal.find('.transaction-total').html( '&mdash;' )
      return
    }

    this.modal.find('.transaction-total').text( `${this.undelegateTotal(amount)} ${App.config.denom}` )

    if( !this.checkUndelegateAmount( amount ) ) {
      this.modal.find('.amount-warning').hide()
      this.setUndelegateAmount( null )
      const msg = amount == 0 ?
        `You can't undelegate <tt>0 ${App.config.denom}</tt>...` :
        `The amount to undelegate must take transaction fees into account.<br/><b>Max: <tt class='text-md'>${this.maxUndelegate()} ${App.config.denom}</tt></b>`
      this.modal.find('.amount-error').html(msg).show()
      this.modal.find('.submit-undelegate').attr( 'disabled', 'disabled' )
    }
    else {
      if( amount == this.maxUndelegate() ) {
        const msg = `It is recommended to leave some ${App.config.denom} in your account to pay fees on future transactions!`
        this.modal.find('.amount-warning').html(msg).show()
      }
      else {
        this.modal.find('.amount-warning').hide()
      }
      this.setUndelegateAmount( amount )
      this.modal.find('.amount-error').hide()

      if ( this.fromValidatorAddress != undefined && this.fromValidatorAddress != "null" ) {
        this.modal.find('.undelegate-form').data( 'disabled', false )
        this.modal.find('.submit-undelegate').removeAttr( 'disabled' )
      } else if (this.modal.find('.undelegate-form').data( 'disabled' ) == false){
        this.modal.find('.undelegate-form').data( 'disabled', true )
        this.modal.find('.submit-undelegate').attr( 'disabled', 'disabled' )
      }
    }
  }
}

App.Common.UndelegateModal = UndelegateModal