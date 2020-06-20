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

    let triggeredGAEvent =  false;
    this.modal.on( 'shown.bs.modal', async () => {
      this.reset()

      if( !triggeredGAEvent ) { ga('send', 'event', 'delegation', 'started') }
      const ledgerSigner = async () => {
        const signMessage = {} || ``
        this.ledger = new Ledger(
           false,
           [44, 118, 0, 0, 0],
          'secret'
          )

        await this.ledger.connect();

        const publicKey = await this.ledger.getPubKey();
        const publicAddress = await this.ledger.getCosmosAddress();
        const showAppVersion = await this.ledger.getCosmosAppVersion();
        var getOpenApp = await this.ledger.getOpenApp();
        var cosmosAddress = await this.ledger.getCosmosAddress();

        return publicAddress;
      }

      this.publicAddress = await ledgerSigner();
      this.publicKey = await this.ledger.getPubKey();
      this.txContext = await this.setTxContext();
      this.txContext = this.txContext.value

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
      
      if( _.includes( App.config.existingDelegators, this.publicAddress ) ) {
        this.modal.find('.step-choice')
          .find('.reward-balance').text( `${5} ${App.config.denom}` ).end()
          .show()
        if( 5 == 0 ) {
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

      const txObject = this.delegationMsgObject();
      console.log(txObject);
      let createMessage = JSON.stringify(removeEmptyProperties(this.createSkeleton(this.txContext, [txObject])));
      console.log(txObject);
      console.log(createMessage);

      this.modal.find('.transaction-json').text(
        JSON.stringify( txObject, undefined, 2 )
      )
      const sig = await this.ledger.sign(createMessage);
      console.log(Buffer.from(sig).toString('base64'))
      let appliedSig = this.createBroadcastTx(this.txContext, [txObject], sig);

      console.log(JSON.stringify(appliedSig));
      let broadcastError = null
      if( appliedSig ) {
        const broadcastResult = await this.broadcastTransaction( appliedSig )
        console.log(broadcastResult);
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
        .find('.delegation-error').text(broadcastError || "Unknown error")
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

  delegationMsgObject() {
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

  createSkeleton(txContext, msgs = [], sigs = null) {
    if (typeof txContext === 'undefined') {
      throw new Error('undefined txContext');
    }
    if (typeof txContext.account_number === 'undefined') {
      throw new Error('txContext does not contain the accountNumber');
    }
    if (typeof txContext.sequence === 'undefined') {
      throw new Error('txContext does not contain the sequence value');
    }

    const txSkeleton = {
      type: "cosmos-sdk/StdTx",
      fee: {
        amount: [
          {
            denom: App.config.remoteDenom,
            amount: this.delegationTransactionFee( false ).toString()
          }
        ],
        gas: this.DELEGATION_GAS_WANTED.toString()
      },
      memo: txContext.memo || this.MEMO,
      msgs: msgs,
      msg: msgs,
      sequence: 0,
      account_number: txContext.account_number,
      chain_id: 'secret-1',
      signatures: sigs
    }
    // return Ledger.applyGas(txSkeleton, DEFAULT_GAS);
    return txSkeleton;
  }

  createBroadcastTx(txContext, msgs, sig) {
    return {
      type: "cosmos-sdk/StdTx",
      value: {
        msg: msgs,
        fee: {
          amount: [
            {
              denom: App.config.remoteDenom,
              amount: this.delegationTransactionFee( false ).toString()
            }
          ],
          gas: this.DELEGATION_GAS_WANTED.toString()
        },
        memo: txContext.memo || this.MEMO,
        chain_id: 'secret-1',
        signatures: [
          {
            signature: Buffer.from(sig).toString('base64'),
            account_number: txContext.account_number,
            sequence: 0,
            pub_key: {
              type: "tendermint/PubKeySecp256k1",
              value: Buffer.from(this.publicKey).toString('base64')
            },
          }
        ]
      },
      
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
      account_number: txContext.account_number.toString(),
      chain_id: txContext.chain_id,
      fee: tx.value.fee,
      memo: tx.value.memo,
      msgs: tx.value.msg,
      sequence: txContext.sequence.toString(),
    };

    return JSON.stringify(canonicalizeJson(txFieldsToSign));
  }

  async broadcastTransaction( txPayload ) {
    if( !txPayload ) { return false }
    console.log( App.config.broadcastTxPath);
    // console.log('FINAL TX', txPayload)
    const response = await fetch( App.config.broadcastTxPath, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': $('meta[name=csrf-token]').attr('content')
      },
      body: JSON.stringify( { tx: txPayload, mode: 'block' } )
    } )
    const responseData = await response.json()
    return responseData
  }

  applySignature(unsignedTx, txContext, secp256k1Sig) {
    if (typeof unsignedTx === 'undefined') {
        throw new Error('undefined unsignedTx');
    }
    if (typeof txContext === 'undefined') {
        throw new Error('undefined txContext');
    }
    if (typeof this.publicKey === 'undefined') {
        throw new Error('txContext does not contain the public key (pk)');
    }
    if (typeof txContext.account_number === 'undefined') {
        throw new Error('txContext does not contain the accountNumber');
    }
    if (typeof txContext.sequence === 'undefined') {
        throw new Error('txContext does not contain the sequence value');
    }

    const tmpCopy = Object.assign({}, unsignedTx, {});

    tmpCopy.value.signatures = [
        {
            signature: secp256k1Sig.toString('base64'),
            account_number: txContext.account_number.toString(),
            sequence: txContext.sequence.toString(),
            pub_key: {
                type: 'tendermint/PubKeySecp256k1',
                value: this.publicKey//Buffer.from(txContext.pk, 'hex').toString('base64'),
            },
        },
    ];
    return tmpCopy;
}
}

function removeEmptyProperties(jsonTx) {
  if (Array.isArray(jsonTx)) {
    return jsonTx.map(removeEmptyProperties)
  }

  // string or number
  if (typeof jsonTx !== `object`) {
    return jsonTx
  }

  const sorted = {}
  Object.keys(jsonTx)
    .sort()
    .forEach((key) => {
      if (jsonTx[key] === undefined || jsonTx[key] === null) return

      sorted[key] = removeEmptyProperties(jsonTx[key])
    })
  return sorted
}

App.Common.DelegationModal = DelegationModal
