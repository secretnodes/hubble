module Transactionlike
  extend ActiveSupport::Concern

  included do |klass|
    namespace = klass.name.deconstantize.constantize

    belongs_to :chain, class_name: "#{namespace}::Chain"
    belongs_to :block, class_name: "#{namespace}::Block"
    belongs_to :proposal, class_name: "#{namespace}::Governance::Proposal", optional: true, primary_key: :ext_id

    has_and_belongs_to_many :accounts, class_name: "#{namespace}::Account", join_table: "#{namespace.to_s.downcase}_accounts_#{namespace.to_s.downcase}_transactions"

    default_scope { order('height DESC') }

    enum transaction_type: [:send_token, :delegate_token, :undelegate, :redelegate, :submit_proposal,
                            :deposit, :vote, :swap, :withdraw_all_rewards, :withdraw_rewards, :withdraw_commission,
                            :unjail, :edit_validator, :modify_withdraw_address, :create_validator]
    validates :hash_id, uniqueness: true, presence: true
    validates :height, :transaction_type, presence: true
  end

  def to_param; hash_id.to_s; end

  def swap?
    transaction_type == :swap
  end

  module ClassMethods
    def convert_transaction_type( raw_type )
      sanitized = raw_type.sub( /^cosmos-sdk\//, '' )
      case sanitized
        when 'MsgSend' then :send_token
        when 'MsgDelegate' then :delegate_token
        when 'MsgUndelegate' then :undelegate
        when 'MsgBeginRedelegate' then :redelegate
        when 'MsgSubmitProposal' then :submit_proposal
        when 'MsgDeposit' then :deposit
        when 'MsgVote' then :vote
        when 'tokenswap/TokenSwap' then :swap
        when 'MsgWithdrawValidatorRewardsAll' then :withdraw_all_rewards
        when 'MsgWithdrawDelegationReward' then :withdraw_rewards
        when 'MsgWithdrawValidatorCommission' then :withdraw_commission
        when 'MsgUnjail' then :unjail
        when 'MsgEditValidator' then :edit_validator
        when 'MsgModifyWithdrawAddress' then :modify_withdraw_address
        when 'MsgCreateValidator' then :create_validator
      end
    end

    def error_message(code)
      case code
        when 1 then "Internal Error"
        when 2 then "Transaction Parse Error"
        when 3 then "Invalid Sequence"
        when 4 then "Unauthorized"
        when 5 then "Insufficient Funds"
        when 6 then "Unknown Request"
        when 7 then "Invalid Address"
        when 8 then "Invalid Public Key"
        when 9 then "Unknown Address"
        when 10 then "Insufficient Coins"
        when 11 then "Invalid Coins"
        when 12 then "Out of Gas"
        when 13 then "Memo Too Large"
        when 14 then "Insufficient Fee"
        when 15 then "Too Many Signatures"
  
        when 103 then "Validator Not Jailed"
  
        else "Unknown Error"
      end
    end

    def get_proposal_id(event)
      attributes = event['attributes']
      attributes.select { |a| a['key'] == 'proposal_id' }[0]['value']
    end

    def assemble(chain, block, hash)
      tx = hash['tx']
      msg = tx['value']['msg']
      logs = hash['logs']
      height = hash['height']
      fee = tx['value']['fee']['amount'] == [] ? nil : tx['value']['fee']['amount'][0]['amount']
      transaction_type = convert_transaction_type(msg[0]['type'])
      signature = tx['value']['signatures']
      hash_id = hash['txhash']
      timestamp = hash['timestamp']
      msg = tx['value']['msg']
      error_message = hash['code'] ? error_message(hash['code']) : nil
      memo = tx['value']['memo']
      
      proposal_id = if [:deposit, :vote].include?(transaction_type)
        msg[0]['value']['proposal_id']
      elsif transaction_type == :submit_proposal && error_message.nil?
        get_proposal_id(logs[0]['events'][1])
      else
        nil
      end

      transaction = chain.namespace::Transaction.create(
        chain_id: chain.id,
        block_id: block.id,
        height: height,
        transaction_type: transaction_type,
        raw_transaction: hash,
        gas_wanted: hash['gas_wanted'],
        gas_used: hash['gas_used'],
        fee: fee,
        timestamp: timestamp,
        message: msg,
        proposal_id: proposal_id.present? ? proposal_id : nil,
        signature: signature,
        hash_id: hash_id,
        memo: memo,
        error_message: error_message,
        logs: logs
      )
      if transaction.invalid?
        raise RuntimeError.new("Could not save transaction for hash_id #{hash_id}") if transaction.invalid?
      else
        return transaction
      end
    end

    def swap_address_count
      addresses = []
      messages = swap.pluck(:message).flatten
      messages.map { |m| addresses << m['value']['Receiver'] }
      addresses.uniq.count
    end
  end
end