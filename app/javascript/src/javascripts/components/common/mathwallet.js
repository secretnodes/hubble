const network = {
  blockchain: "secretnetwork",
  chainId: "secret-2"
};

const DEFAULT_MEMO = 'https://puzzle.report';
const DEFAULT_GAS = 200000;
export const DEFAULT_GAS_PRICE = 0.25;

export class MathWallet {
  constructor() {
  }

  async setupConnection() {

    await this.initMathExtension();

    const identity = await mathExtension.getIdentity(network);
    console.log(identity);

    this.publicAddress = identity['account'];

    this.txContext = this.formatTxContext(await this.setTxContext());

    if (this.txContext.coins.length == 0) {
      this.txContext.address = this.publicAddress;
      this.accountBalance = 0;
      this.scaledBalance = 0;
    } else {
      this.accountBalance = this.txContext.coins[0].amount;
      this.scaledBalance = this.scale(this.accountBalance);
    }
  }

  async initMathExtension(){
    var tries = 10;
    for (var i = 0; i < tries; i++) {
      var loaded = await new Promise((resolve, reject) => {
        setTimeout(function(){
          resolve(typeof window.mathExtension != 'undefined');
        }, 100);
      });
      if(loaded) return window.mathExtension;
    }
    return false;
  }

  async setTxContext( ) {
    let url = '/secret/chains/secret-2/accounts/' + this.publicAddress + '?validator=' + App.config.validatorOperatorAddress;
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
    newObject.delegations = txContext['delegations'];
    newObject.chain_id = 'secret-2';
    return newObject;
  }

  scale ( number ) {
    return Math.round((number / App.config.remoteScaleFactor) * 1000000) / 1000000;
  }

  static createTx(txContext, msgs, gasAmount) {
    var transaction = {
      chain_id: network.chainId,
      account_number: txContext.account_number.toString(),
      sequence: txContext.sequence.toString(),
      fee: {
        amount: [{
          denom: txContext.coins[0].denom,
          amount: Math.round(gasAmount * DEFAULT_GAS_PRICE).toString()
        }],
        gas: gasAmount,
      },
      memo: DEFAULT_MEMO,
      msgs: msgs
    };

    return transaction;
  }

  async buildAndSign(transaction) {
    let signedTransaction = await mathExtension.requestSignature(transaction, network)

    let trx = {
      "msg": transaction.msgs,
      "memo": transaction.memo,
      "fee": transaction.fee,
      "signatures": [{
        ...signedTransaction,
      }]
    };
    return trx;
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
    return responseData;
  }

  async addWallet( userId, chainId ) {
    if( !userId ) { return false }

    let payload = {
      wallet: {
        user_id: userId,
        wallet_type: 'mathwallet',
        public_address: this.publicAddress,
        public_key: this.txContext.public_key,
        chain_id: 1,
        chain_type: 'Secret',
        account_index: 0
      }
    }

    const response = await fetch( '/api/v1/wallets', {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': $('meta[name=csrf-token]').attr('content')
      },
      body: JSON.stringify( payload )
    } )
    const responseData = await response.json()
    return responseData
  }
}