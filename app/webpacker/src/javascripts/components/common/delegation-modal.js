import Ledger from "@lunie/cosmos-ledger";
import _ from 'lodash';


class DelegationModal {
  constructor( el ) {
    this.DELEGATION_GAS_WANTED = 150000
    this.REDELEGATION_GAS_WANTED = 200000
    this.GAS_PRICE = 0.025
    this.MEMO = 'Delegate to your favorite validator with Puzzle - https://puzzle.secretnodes.org'
    this.modal = el
    this.reset()
    this.modal.on( 'hidden.bs.modal', () => this.reset() )

    const API_URL = 'http://65.19.134.86:26657';
    const ADDRESS = "enigma1jk9zmatkhj2qh37j6ym9xt40s697adf5txv3z2";
    const Cosmos = require('@lunie/cosmos-js/src/index.js').default;

    this.cosmos = new Cosmos(API_URL, ADDRESS);
    console.log(this.cosmos);

    console.log('tangent');
    let triggeredGAEvent =  false;
    this.modal.on( 'shown.bs.modal', async () => {
      this.reset()

      if( !triggeredGAEvent ) { ga('send', 'event', 'delegation', 'started') }
      const hdPath = Buffer.from([44, 118, 0, 0, 0], 'hex')
      console.log(hdPath);
      const ledgerSigner = async () => {
        const signMessage = {} || ``
        this.ledger = new Ledger(
           false,
          hdPath,
          'enigma'
          )

        await this.ledger.connect();

        console.log(this.ledger.hdPath);

        const publicKey = await this.ledger.getPubKey();
        const publicAddress = await this.ledger.getCosmosAddress();
        const showAppVersion = await this.ledger.getCosmosAppVersion();
        var getOpenApp = await this.ledger.getOpenApp();
        var cosmosAddress = await this.ledger.getCosmosAddress();

        return publicAddress;
      }

      this.publicAddress = await ledgerSigner();
      this.txContext = await this.setTxContext();

      const setupError = null;
      if( setupError ) {
        this.modal.find('.delegation-step').hide()
        this.modal.find('.step-error')
          .find('.delegation-error').text(setupError == "" ? "Unknown error." : setupError)
          .end().show()
        return
      }
      this.accountBalance = this.formatBalance(await this.getAccountBalance());
      // console.log('GOT ADDRESS INFO', this.ledger.accountInfo)
      this.modal.find('.step-setup').hide()
      
      console.log(this.txContext.value)
      if( _.includes( App.config.existingDelegators, this.publicAddress ) ) {
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
          this.getAccountBalance()
            .then(response=> this.newDelegation(response))
        } )
      }
      else {
        this.getAccountBalance()
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

    var balance = this.formatBalance(response) / App.config.remoteScaleFactor;
    console.log(this.accountBalance);
    this.modal.find('.modal-dialog').addClass('modal-lg')
    this.modal.find('.step-new-delegation')
      .find('.account-balance').text( `${balance} ${App.config.denom}` ).end()
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

      const txObject = this.delegationTransactionObject();
      let createMessage = this.createSkeleton(this.txContext, [txObject]);
      console.log(txObject);
      console.log(createMessage);

      const signature = await this.ledger.sign([createMessage]);
      this.modal.find('.transaction-json').text(
        JSON.stringify( txObject, undefined, 2 )
      )

      console.log(signature);
      // const txPayload = await this.ledger.sign( msg )
        const txPayload = '';
      let broadcastError = null
      if( txPayload ) {
        // const broadcastResult = await this.ledger.broadcastTransaction( txPayload )
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
      console.log(txObject);
    const txPayload = await this.ledger.sign( txObject )
    let broadcastError = null
    console.log(txPayload);
    if( txPayload ) {
      // const broadcastResult = await this.ledger.broadcastTransaction( txPayload )
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
          type: 'cosmos-sdk/MsgDelegate',
          value: {
            delegator_address: this.publicAddress,
            validator_address: App.config.validatorOperatorAddress,
            amount: { denom: App.config.remoteDenom, amount: this.delegationAmount.toString() }
          }
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
    return (this.accountBalance - this.delegationTransactionFee(false)) / App.config.remoteScaleFactor
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

  createSkeleton(txContext, msgs = []) {
    if (typeof txContext === 'undefined') {
      throw new Error('undefined txContext');
    }
    if (typeof txContext.value.account_number === 'undefined') {
      throw new Error('txContext does not contain the accountNumber');
    }
    if (typeof txContext.value.sequence === 'undefined') {
      throw new Error('txContext does not contain the sequence value');
    }
    const txSkeleton = {
      "type": 'auth/StdTx',
      "value": {
        "msg": msgs,
        "fee": '',
        "memo": txContext.value.memo || this.MEMO,
        "signatures": [{
          "signature": 'N/A',
          "account_number": txContext.value.account_number.toString(),
          "sequence": txContext.value.sequence.toString(),
          "pub_key": {
            "type": 'tendermint/PubKeySecp256k1',
            "value": txContext.pk || 'PK',
          },
        }],
      },
    };
    // return Ledger.applyGas(txSkeleton, DEFAULT_GAS);
    return txSkeleton;
  }

  createLedgerTx() {
    return {
      "msg": [
        {
          "type": `cosmos-sdk/Send`,
          "value": {
            "inputs": [
              {
                "address": this.publicAddress,
                "coins": [{ "denom": `STAKE`, "amount": `1` }]
              }
            ],
            "outputs": [
              {
                "address": App.config.validatorOperatorAddress,
                "coins": [{ "denom": `STAKE`, "amount": `1` }]
              }
            ]
          }
        }
      ],
      "fee": { "amount": [{ "denom": ``, "amount": `0` }], "gas": `21906` },
      "signatures": null,
      "memo": ``
    }
  }

  getBytesToSign(tx, txContext) {
    if (typeof txContext === 'undefined') {
      throw new Error('txContext is not defined');
    }
    if (typeof txContext.chainId === 'undefined') {
      throw new Error('txContext does not contain the chainId');
    }
    if (typeof txContext.accountNumber === 'undefined') {
      throw new Error('txContext does not contain the accountNumber');
    }
    if (typeof txContext.sequence === 'undefined') {
      throw new Error('txContext does not contain the sequence value');
    }

    const txFieldsToSign = {
      account_number: txContext.accountNumber.toString(),
      chain_id: txContext.chainId,
      fee: tx.value.fee,
      memo: tx.value.memo,
      msgs: tx.value.msg,
      sequence: txContext.sequence.toString(),
    };

    return JSON.stringify(canonicalizeJson(txFieldsToSign));
  }
}

App.Common.DelegationModal = DelegationModal
