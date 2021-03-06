module Api
  module V1
    class AccountsController < ApplicationController
      def balance
        chain = Secret::Chain.find params[:chain_id]

        syncer = chain.syncer( 3_000 )
        balance = syncer.get_account_balances params[:address]

        if balance
          render json: { balance: balance }, status: :ok
        else
          render json: { error: "We could not return the balance for that address. Please try again." }, status: :internal_server_error
        end

        return
      end

      def info
        chain = Secret::Chain.find params[:chain_id]

        syncer = chain.syncer( 3_000 )
        info = syncer.get_account_info params[:address]

        if info
          render json: info['value'], status: :ok
        else
          render json: { error: "We could not return the info for that address. Please try again." }, status: :internal_server_error
        end
      end
    end
  end
end