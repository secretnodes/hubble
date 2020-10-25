class AccountBalanceWorker
  include Sidekiq::Worker
  sidekiq_options queue: :balances, retry: false, backtrace: true

  def perform(network='secret')
    network.titleize.constantize::Chain.enabled.find_each do |chain|
      TaskLock.with_lock!(:balances, "#{network}-#{chain.ext_id}") do
        syncer = chain.syncer
        chain.accounts.each do |account|
          balance_arr = syncer.get_account_balances(account.address)
          wallet_balance = balance_arr.present? ? balance_arr[0]['amount'].to_i : 0
          delegations = syncer.get_account_delegations(account.address)
          unbonding = syncer.get_account_unbonding_delegations(account.address)
          rewards = syncer.get_account_rewards(account.address)

          if delegations.present?
            delegation_total = delegations.inject(0) { |sum, hash| sum + hash['balance']['amount'].to_i }
          else
            delegation_total = 0
          end

          if unbonding.present?
            unbonding_total = unbonding.inject(0) { |sum, hash| sum + hash['entries'][0]['balance'].to_i  }
          else
            unbonding_total = 0
          end

          if rewards.present?
            rewards_total = rewards.inject(0) { |sum, hash| sum + hash['amount'].to_i  }
          else
            rewards_total = 0
          end

          if account.validator.present? 
            commission_total = (syncer.get_validator_commission account.validator.owner)[0]['amount'].to_f
          else
            commission_total = 0
          end

          account.update!(
            available_balance: wallet_balance,
            delegated_balance: delegation_total,
            rewards_balance: rewards_total,
            unbonding_balance: unbonding_total,
            commission_balance: commission_total,
            total_balance: wallet_balance + delegation_total + rewards_total + unbonding_total + commission_total
          )
        end
      end

      chain.update!(last_balance_sync: Time.now)
    end

  ensure
    
    AccountBalanceWorker.perform_in(1.second)
  end
end