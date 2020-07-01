module Api
  module V1
    class WalletsController < ApplicationController
      def create
        @wallet = Wallet.new(wallet_params)

        if @wallet.save!
          render json: { message: "Your wallet was successfully saved." }, status: :created
        else
          render json: { error: "There was a problem saving this wallet to your account. Please try again." }, status: :unprocessable_entity
        end
        return
      end

      private

      def wallet_params
        params.require(:wallet).permit(
          :account_index,
          :public_address,
          :account_balance,
          :public_key,
          :chain_id,
          :chain_type,
          :wallet_type,
          :user_id
        )
      end
    end
  end
end
