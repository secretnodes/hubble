const { GaiaApi } = require("@chainapsis/cosmosjs/gaia/api");
const { AccAddress, ValAddress } = require("@chainapsis/cosmosjs/common/address");
const { Coin } = require("@chainapsis/cosmosjs/common/coin");
const { MsgDelegate, MsgBeginRedelegate } = require("@chainapsis/cosmosjs/x/staking");
const { ProposalKind, VoteOption, MsgSubmitProposal, MsgDeposit, MsgVote } = require("@chainapsis/cosmosjs/x/gov");
const { MsgWithdrawDelegatorReward } = require("@chainapsis/cosmosjs/x/distribution");
const {defaultBech32Config} = require("@chainapsis/cosmosjs/core/bech32Config");

export class Keplr {
  constructor() {
  }

  async setupConnection() {

    if (!window.cosmosJSWalletProvider) {
      alert("Please install keplr extension");
    }

    this.cosmosJS = new GaiaApi({
      chainId: "secret-1",
      walletProvider: window.cosmosJSWalletProvider,
      rpc: "https://client.secretnodes.org",
      rest: "https://lcd.secretnodes.org",
    }, {
      bech32Config: defaultBech32Config("secret")
    });

    await this.cosmosJS.enable();

    const identity = await this.cosmosJS.getKeys()
    console.log(identity);

    this.accAddress = new AccAddress(identity[0].address, "secret");

    this.publicAddress = identity[0].bech32Address;

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

  async sendDelegationMsg(delegator_addr, validator_addr, amount, gas, fee, memo) {
    const valAddress = ValAddress.fromBech32(validator_addr, "secretvaloper");
    const delAddress = AccAddress.fromBech32(delegator_addr, 'secret');

    const msg = new MsgDelegate(delAddress, valAddress, new Coin("uscrt", amount));

    const result = await this.sendMsg([msg], gas, memo, fee);
    return result;
  }

  async sendWithdrawalMsg(delegator_addr, validator_addr, gas, fee, memo) {
    const valAddress = ValAddress.fromBech32(validator_addr, "secretvaloper");
    const delAddress = AccAddress.fromBech32(delegator_addr, 'secret');

    const msg = new MsgWithdrawDelegatorReward(delAddress, valAddress);

    const result = await this.sendMsg([msg], gas, memo, fee);
    return result;
  }

  async sendRedelegationMsg(delegator_addr, val_src_addr, val_dst_addr, amount, gas, fee, memo) {
    const valSrcAddress = ValAddress.fromBech32(val_src_addr, "secretvaloper");
    const valDstAddress = ValAddress.fromBech32(val_dst_addr, "secretvaloper");
    const delAddress = AccAddress.fromBech32(delegator_addr, 'secret');

    const msg = new MsgBeginRedelegate(delAddress, valSrcAddress, valDstAddress, new Coin('uscrt', amount));
    
    const result = await this.sendMsg([msg], gas, memo, fee);
    return result;
  }

  async sendSubmitProposalMsg(title, description, proposerAddr, deposit, gas, fee, memo) {
    const propAddr = AccAddress.fromBech32(proposerAddr, 'secret');
    const propType = new ProposalKind(1);
    
    const msg = new MsgSubmitProposal(title, description, propType, propAddr, [new Coin('uscrt', deposit)]);

    const result = await this.sendMsg([msg], gas, memo, fee);
    return result;
  }

  async sendDepositMsg(proposal_id, addr, deposit, gas, fee, memo) {
    const propAddr = AccAddress.fromBech32(addr, 'secret');

    const msg = new MsgDeposit(proposal_id, propAddr, [new Coin('uscrt', deposit)])

    const result = await this.sendMsg([msg], gas, memo, fee);
    return result;
  }

  async sendVoteMsg(proposal_id, addr, option, gas, fee, memo) {
    const voteAddr = AccAddress.fromBech32(addr, 'secret');
    const vote = new VoteOption(this.getVoteOption(option));

    const msg = new MsgVote(proposal_id, voteAddr, vote);

    const result = await this.sendMsg([msg], gas, memo, fee);
  }

  async sendMsg(msg, gas, memo, fee) {
    const result = await this.cosmosJS.sendMsgs(msg, {
      gas: gas,
      memo: memo,
      fee: new Coin("uscrt", fee)
  }, "commit");
    return result;
  }

  getVoteOption(option) {
    let num = null;
    switch(option.toLowerCase().trim()){
      case "yes":
        num = 1;
        break;
      case "abstain":
        num = 2;
        break;
      case "no":
        num = 3;
        break;
      case "nowithveto":
        num = 4;
        break;
    }
    return num;
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
    newObject.delegations = txContext['delegations'];
    newObject.chain_id = 'secret-1';
    return newObject;
  }

  scale ( number ) {
    return Math.round((number / App.config.remoteScaleFactor) * 1000000) / 1000000;
  }

  async addWallet( userId, chainId ) {
    if( !userId ) { return false }

    let payload = {
      wallet: {
        user_id: userId,
        wallet_type: 'keplr',
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