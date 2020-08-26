class Common::AccountsController < Common::BaseController
  before_action :ensure_chain

  def index
    @accounts = @chain.accounts.order('total_balance DESC')

  end

  def show
    respond_to do |format|
      format.html {
        @found_account = @chain.accounts.find_by( address: params[:id] )
        page_title @chain.network_name, @chain.name, params[:id]
        meta_description "Delegations, Recent Delegation Transactions, Balance, and Pending Rewards for #{params[:id]}#{" (owner of #{@found_account.validator.long_name})" if @found_account.try(:validator)}"
      }
      format.json {
        syncer = @chain.syncer( 3000 )

        if params.has_key?(:dashboard_info)
          account_info = {
            balances: syncer.get_account_balances( params[:id] ),
            delegations: syncer.get_account_delegations( params[:id] ),
            rewards: syncer.get_account_rewards( params[:id] )
          }
        else
          account_info = syncer.get_account_info( params[:id] )
          account_info[:delegations] = syncer.get_account_delegations( params[:id] )

          if account_info && params[:validator]
            account_info['rewards_for_validator'] = syncer.get_account_rewards( params[:id], params[:validator] )
          end
        end

        render json: account_info
      }
    end
  end
end
