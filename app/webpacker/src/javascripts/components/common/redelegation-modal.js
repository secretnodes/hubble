import { DEFAULT_MEMO, Ledger } from './ledger.js';
import { MathWallet } from './mathwallet.js'
import { Keplr } from './keplr.js'

class RedelegationModal {
  constructor( el ) {
    this.REDELEGATION_GAS_WANTED = 300000
    this.GAS_PRICE = 0.01
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
    this.modal.find('.submit-redelegation').text('Sign with Ledger');
    this.modal.find('.redelegation-step').hide()
    this.newRedelegation();
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
    let btn = this.modal.find('.submit-redelegation').text("Sign with Mathwallet");
    this.modal.find('.redelegation-step').hide()
    this.newRedelegation();
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
    let btn = this.modal.find('.submit-redelegation').text("Sign with Keplr");
    this.modal.find('.redelegation-step').hide()
    this.newRedelegation();
  }

  reset() {
    this.modal.find('.modal-dialog').removeClass('modal-lg')
    this.modal.find('.redelegation-step').hide()
    this.modal.find('.step-choose-wallet').show()
    this.modal.find('.redelegation-amount').val('').off('input')
    this.modal.find('.set-max').off('click')
    this.modal.find('.redelegation-form').off('submit').data( 'disabled', true )
    this.modal.find('.submit-redelegation').attr( 'disabled', 'disabled' )
    this.modal.find('.choice-redelegate').removeAttr('disabled')
    this.modal.find('.show-transaction-json').off('click').show()
    this.modal.find('.transaction-json-container').hide()
    this.modal.find('.amount-error').hide()
    this.modal.find('.amount-warning').hide()
    this.modal.find('.ledger-instructions').hide()
    this.modal.find('.view-transaction').attr( 'href', '' )
  }

  newRedelegation() {
    this.modal.find('.modal-dialog').addClass('modal-lg')
    console.log(this.wallet.txContext.delegations);

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
      this.max_redelegation_amount = this.wallet.txContext.delegations[delegation_index]['balance']['amount'];
      this.modal.find('.account-balance').text( `${this.maxRedelegation()} ${App.config.denom}` ).end()
      this.validateRedelegationForm(e);
    })

    this.modal.find('.to-validator').on( 'change', ( e ) => {
      this.validator_dst_address = $(e.currentTarget).val();
      this.validateRedelegationForm(e);
    })

    this.modal.find('.step-redelegation')
      .find('.account-balance').text( `${this.maxRedelegation()} ${App.config.denom}` ).end()
      .find('.account-address').html( this.wallet.publicAddress ).end()
      .find('.transaction-fee').text( `${this.redelegationTransactionFee()} ${App.config.denom}` ).end()
      .show()

    this.modal.find('.set-max').click( ( e ) => {
      e.preventDefault()
      this.modal.find('.redelegation-amount').val( this.maxRedelegation() ).trigger('set-to-max')
    } )

    this.modal.find('.redelegation-amount').on( 'input set-to-max', ( e ) => {
      this.validateRedelegationForm(e);
    } )

    this.modal.find('.redelegation-form').submit( async ( e ) => {
      e.preventDefault()

      if( $(e.currentTarget).data('disabled') ) { return }

      this.modal.find('.redelegation-step').hide()
      this.modal.find('.modal-dialog').removeClass('modal-lg')
      this.modal.find('.step-confirm').show()

      this.validator_dst_address = this.modal.find('.to-validator option:selected').val();
      let broadcastError = null;

      if (this.wallet_type == "keplr") {
        const msg = await this.wallet.sendRedelegationMsg(
          this.wallet.publicAddress,
          this.fromValidatorAddress,
          this.validator_dst_address,
          this.redelegationAmount,
          this.REDELEGATION_GAS_WANTED,
          this.redelegationTransactionFee(false),
          this.MEMO);

        if (msg.deliverTx.code == 0) {
          let hash = Buffer.from(msg.hash).toString('hex');
          this.modal.find('.redelegation-step').hide()
          this.modal.find('.view-transaction').attr( 'href', App.config.viewTxPath.replace('TRANSACTION_HASH', hash) )
          this.modal.find('.step-complete').show()
          ga('send', 'event', 'redelegation', 'completed')
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

          console.log(this.txSignature);

          const broadcastResult = await this.wallet.broadcastTransaction( this.txSignature )
          if( broadcastResult.ok ) {
            this.modal.find('.redelegation-step').hide()
            this.modal.find('.view-transaction').attr( 'href', App.config.viewTxPath.replace('TRANSACTION_HASH', broadcastResult.txhash) )
            this.modal.find('.step-complete').show()
            ga('send', 'event', 'redelegation', 'completed')
            return
          }
          else {
            broadcastError = broadcastResult.error_message
          }
        }
      }

      ga('send', 'event', 'redelegation', 'failed')
      this.modal.find('.redelegation-step').hide()

      this.modal.find('.step-error')
        .find('.redelegation-error').text(broadcastError || this.wallet.signError || "Unknown error")
        .end().show()
    } )
  }

  redelegationTransactionObject() {
    return [
      {
        type: 'cosmos-sdk/MsgBeginRedelegate',
        value: {
          amount: { amount: this.redelegationAmount.toString(), denom: App.config.remoteDenom },
          delegator_address: this.wallet.publicAddress,
          validator_dst_address: this.validator_dst_address,
          validator_src_address: this.fromValidatorAddress
        }
      }
    ]
  }

  redelegationTransactionFee( scale=true ) {
    return (this.REDELEGATION_GAS_WANTED * this.GAS_PRICE) / (scale ? App.config.remoteScaleFactor : 1)
  }

  redelegationTotal( amount ) {
    return ((amount * App.config.remoteScaleFactor) + this.redelegationTransactionFee(false)) / App.config.remoteScaleFactor
  }

  maxRedelegation() {
    return (this.max_redelegation_amount) / App.config.remoteScaleFactor
  }

  checkRedelegationAmount( amount ) {
    return amount > 0 && amount <= this.maxRedelegation()
  }

  setRedelegationAmount( amount ) {
    this.redelegationAmount = amount * App.config.remoteScaleFactor
  }

  validateRedelegationForm( e ) {
    const amount = parseFloat( this.modal.find('.redelegation-amount').val() )
      if( isNaN( amount ) ) {
        this.modal.find('.amount-warning').hide()
        this.modal.find('.amount-error').hide()
        this.modal.find('.redelegation-form').data( 'disabled', true )
        this.modal.find('.submit-redelegation').attr( 'disabled', 'disabled' )
        this.modal.find('.transaction-total').html( '&mdash;' )
        return
      }

      this.modal.find('.transaction-total').text( `${this.redelegationTotal(amount)} ${App.config.denom}` )

      if( !this.checkRedelegationAmount( amount ) ) {
        this.modal.find('.amount-warning').hide()
        this.setRedelegationAmount( null )
        const msg = amount == 0 ?
          `You can't redelegate <tt>0 ${App.config.denom}</tt>...` :
          `The amount to redelegate must take transaction fees into account.<br/><b>Max: <tt class='text-md'>${this.maxRedelegation()} ${App.config.denom}</tt></b>`
        this.modal.find('.amount-error').html(msg).show()
        this.modal.find('.submit-redelegation').attr( 'disabled', 'disabled' )
      }
      else {
        if( amount == this.maxRedelegation() ) {
          const msg = `It is recommended to leave some ${App.config.denom} in your account to pay fees on future transactions!`
          this.modal.find('.amount-warning').html(msg).show()
        }
        else {
          this.modal.find('.amount-warning').hide()
        }
        this.setRedelegationAmount( amount )
        this.modal.find('.amount-error').hide()
        console.log("from addr = " + this.fromValidatorAddress);
        console.log('')
        console.log(this.modal.find('.redelegation-form').data( 'disabled' ));
        if ( this.fromValidatorAddress != undefined && this.fromValidatorAddress != "null" && this.validator_dst_address != undefined && this.validator_dst_address != 'null' ) {
          console.log('disabled false');
          this.modal.find('.redelegation-form').data( 'disabled', false )
          this.modal.find('.submit-redelegation').removeAttr( 'disabled' )
        } else if (this.modal.find('.redelegation-form').data( 'disabled' ) == false){
          console.log('disabled true')
          this.modal.find('.redelegation-form').data( 'disabled', true )
          this.modal.find('.submit-redelegation').attr( 'disabled', 'disabled' )
        }
      }
  }
}

App.Common.RedelegationModal = RedelegationModal