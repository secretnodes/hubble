import { DEFAULT_MEMO, Ledger } from './ledger.js';
import { MathWallet } from './mathwallet.js'
import { Keplr } from './keplr.js'

class SendModal {
  constructor( el ) {
    this.SEND_GAS_WANTED = 100000
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

    try {
      await this.wallet.addWallet(App.config.userId, App.config.chainId);
    } catch (error) {
      console.log(error);
    }

    this.wallet_type = "ledger";
    let button_text = "Sign with Ledger";
    this.modal.find('.submit-send').text('Sign with Ledger');
    this.modal.find('.send-step').hide()
    this.newSend();
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
    let btn = this.modal.find('.submit-send').text("Sign with Mathwallet");
    this.modal.find('.send-step').hide()
    this.newSend();
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
    let btn = this.modal.find('.submit-send').text("Sign with Keplr");
    this.modal.find('.send-step').hide()
    this.newSend();
  }

  reset() {
    this.modal.find('.modal-dialog').removeClass('modal-lg')
    this.modal.find('.send-step').hide()
    this.modal.find('.step-choose-wallet').show()
    this.modal.find('.send-amount').val('').off('input')
    this.modal.find('.set-max').off('click')
    this.modal.find('.send-form').off('submit').data( 'disabled', true )
    this.modal.find('.submit-send').attr( 'disabled', 'disabled' )
    this.modal.find('.choice-send').removeAttr('disabled')
    this.modal.find('.show-transaction-json').off('click').show()
    this.modal.find('.transaction-json-container').hide()
    this.modal.find('.amount-error').hide()
    this.modal.find('.amount-warning').hide()
    this.modal.find('.ledger-instructions').hide()
    this.modal.find('.view-transaction').attr( 'href', '' )
  }

  newSend() {
    this.modal.find('.modal-dialog').addClass('modal-lg')

    this.modal.find('.to-address').on( 'change', ( e ) => {
      this.toAddress = $(e.currentTarget).val();
      this.validateSendForm(e);
    })

    this.modal.find('.step-send')
      .find('.account-balance').text( `${this.maxSend()} ${App.config.denom}` ).end()
      .find('.account-address').html( this.wallet.publicAddress ).end()
      .find('.transaction-fee').text( `${this.sendTransactionFee()} ${App.config.denom}` ).end()
      .show()

    this.modal.find('.set-max').click( ( e ) => {
      e.preventDefault()
      this.modal.find('.send-amount').val( this.maxSend() ).trigger('set-to-max')
    } )

    this.modal.find('.send-amount').on( 'input set-to-max', ( e ) => {
      this.validateSendForm(e);
    } )

    this.modal.find('.send-form').submit( async ( e ) => {
      e.preventDefault()

      if( $(e.currentTarget).data('disabled') ) { return }

      this.modal.find('.send-step').hide()
      this.modal.find('.modal-dialog').removeClass('modal-lg')
      this.modal.find('.step-confirm').show()

      this.validator_dst_address = this.modal.find('.to-validator option:selected').val();
      let broadcastError = null;

      if (this.wallet_type == "keplr") {
        const msg = await this.wallet.sendSendMsg(
          this.wallet.publicAddress,
          this.toAddress,
          this.sendAmount,
          this.SEND_GAS_WANTED,
          this.sendTransactionFee(false),
          this.MEMO);

        if (msg.deliverTx.code == 0) {
          let hash = Buffer.from(msg.hash).toString('hex');
          this.modal.find('.send-step').hide()
          this.modal.find('.view-transaction').attr( 'href', App.config.viewTxPath.replace('TRANSACTION_HASH', hash) )
          this.modal.find('.step-complete').show()
          ga('send', 'event', 'send', 'completed')
          return
        }
        else {
          broadcastError = msg.deliverTx.log
        }

      } else {

        if (this.wallet_type == "ledger") {
          let txObject = Ledger.createSkeleton(this.wallet.txContext, this.sendTransactionObject());
          let sign = await this.wallet.buildAndSign(this.wallet.txContext, txObject, this.SEND_GAS_WANTED.toString());

          this.modal.find('.transaction-json').text(
            JSON.stringify( txObject, undefined, 2 )
          )

          this.txSignature = Ledger.applySignature(sign.newTxObject, this.wallet.txContext, sign.sigArray);
        } else {
          let txObject = MathWallet.createTx(
            this.wallet.txContext,
            this.sendTransactionObject(),
            this.SEND_GAS_WANTED.toString()
          );


          this.txSignature = await this.wallet.buildAndSign(txObject);
        }

        if( this.txSignature ) {
          const broadcastResult = await this.wallet.broadcastTransaction( this.txSignature )

          if( broadcastResult.ok ) {
            this.modal.find('.send-step').hide()
            this.modal.find('.view-transaction').attr( 'href', App.config.viewTxPath.replace('TRANSACTION_HASH', broadcastResult.txhash) )
            this.modal.find('.step-complete').show()
            ga('send', 'event', 'send', 'completed')
            return
          }
          else {
            broadcastError = broadcastResult.error_message
          }
        }
      }

      ga('send', 'event', 'send', 'failed')
      this.modal.find('.send-step').hide()

      this.modal.find('.step-error')
        .find('.send-error').text(broadcastError || this.wallet.signError || "Unknown error")
        .end().show()
    } )
  }

  sendTransactionObject() {
    return [
      {
        type: 'cosmos-sdk/MsgSend',
        value: {
          amount: [{ amount: this.sendAmount.toString(), denom: App.config.remoteDenom }],
          from_address: this.wallet.publicAddress,
          to_address: this.toAddress
        }
      }
    ]
  }

  sendTransactionFee( scale=true ) {
    return (this.SEND_GAS_WANTED * this.GAS_PRICE) / (scale ? App.config.remoteScaleFactor : 1)
  }

  sendTotal( amount ) {
    return ((amount * App.config.remoteScaleFactor) + this.sendTransactionFee(false)) / App.config.remoteScaleFactor
  }

  maxSend() {
    return (this.wallet.accountBalance - this.sendTransactionFee(false)) / App.config.remoteScaleFactor
  }

  checkSendAmount( amount ) {
    return amount > 0 && amount <= this.maxSend()
  }

  setSendAmount( amount ) {
    this.sendAmount = amount * App.config.remoteScaleFactor
  }

  validateSendForm( e ) {
    const amount = parseFloat( this.modal.find('.send-amount').val() )
    
    if( isNaN( amount ) ) {
      this.modal.find('.amount-warning').hide()
      this.modal.find('.amount-error').hide()
      this.modal.find('.send-form').data( 'disabled', true )
      this.modal.find('.submit-send').attr( 'disabled', 'disabled' )
      this.modal.find('.transaction-total').html( '&mdash;' )
      return
    }

    this.modal.find('.transaction-total').text( `${this.sendTotal(amount)} ${App.config.denom}` )

    if( !this.checkSendAmount( amount ) ) {
      this.modal.find('.amount-warning').hide()
      this.setSendAmount( null )
      const msg = amount == 0 ?
        `You can't send <tt>0 ${App.config.denom}</tt>...` :
        `The amount to send must take transaction fees into account.<br/><b>Max: <tt class='text-md'>${this.maxSend()} ${App.config.denom}</tt></b>`
      this.modal.find('.amount-error').html(msg).show()
      this.modal.find('.submit-send').attr( 'disabled', 'disabled' )
    }
    else {
      if( amount == this.maxSend() ) {
        const msg = `It is recommended to leave some ${App.config.denom} in your account to pay fees on future transactions!`
        this.modal.find('.amount-warning').html(msg).show()
      }
      else {
        this.modal.find('.amount-warning').hide()
      }
      this.setSendAmount( amount )
      this.modal.find('.amount-error').hide()

      if ( this.toAddress != undefined && this.toAddress != '' ) {
        this.modal.find('.send-form').data( 'disabled', false )
        this.modal.find('.submit-send').removeAttr( 'disabled' )
      } else if (this.modal.find('.send-form').data( 'disabled' ) == false){
        this.modal.find('.send-form').data( 'disabled', true )
        this.modal.find('.submit-send').attr( 'disabled', 'disabled' )
      }
    }
  }
}

App.Common.SendModal = SendModal