module Transactionlike
  extend ActiveSupport::Concern

  included do |klass|
    namespace = klass.name.deconstantize.constantize

    belongs_to :chain, class_name: "#{namespace}::Chain"
    belongs_to :block, class_name: "#{namespace}::Block"
    belongs_to :proposal, class_name: "#{namespace}::Governance::Proposal", optional: true, primary_key: :ext_id

    default_scope { order('height DESC') }

    enum transaction_type: [:send_coin, :delegate_coin, :undelegate, :redelegate, :deposit, :vote, :swap, 
                            :withdraw_all_rewards, :withdraw_rewards, :withdraw_commission, 
                            :unjail, :edit_validator, :modify_withdraw_address]
  end

  def to_param; id_hash.to_s; end

  def convert_transaction_type( raw_type )
    sanitized = raw_type.sub( /^cosmos-sdk\//, '' )
    case sanitized
    when 'MsgSend' then :send_coin
    when 'MsgDelegate' then :delegate_coin
    when 'MsgUndelegate' then :undelegate
    when 'MsgBeginRedelegate' then :redelegate
    when 'MsgDeposit' then :deposit
    when 'MsgVote' then :vote
    when 'tokenswap/TokenSwap' then :swap
    when 'MsgWithdrawValidatorRewardsAll' then :withdraw_all_rewards
    when 'MsgWithdrawDelegationReward' then :withdraw_rewards
    when 'MsgWithdrawValidatorCommission' then :withdraw_commission
    when 'MsgUnjail' then :unjail
    when 'MsgEditValidator' then :edit_validator
    when 'MsgModifyWithdrawAddress' then :modify_withdraw_address
    end
  end

  module ClassMethods
    def convert_transaction_type( raw_type )
      sanitized = raw_type.sub( /^cosmos-sdk\//, '' )
      case sanitized
      when 'MsgSend' then :send_coin
      when 'MsgDelegate' then :delegate
      when 'MsgUndelegate' then :undelegate
      when 'MsgBeginRedelegate' then :redelegate
      when 'MsgDeposit' then :deposit
      when 'MsgVote' then :vote
      when 'tokenswap/TokenSwap' then :swap
      when 'MsgWithdrawValidatorRewardsAll' then :withdraw_all_rewards
      when 'MsgWithdrawDelegationReward' then :withdraw_rewards
      when 'MsgWithdrawValidatorCommission' then :withdraw_commission
      when 'MsgUnjail' then :unjail
      when 'MsgEditValidator' then :edit_validator
      when 'MsgModifyWithdrawAddress' then :modify_withdraw_address
      end
    end
  end
end