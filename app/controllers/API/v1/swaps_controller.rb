module Api
  module V1
    class SwapsController < ApplicationController
      def tokens_burned
        if params[:auth_token] != Rails.application.credentials.dig(Rails.env.to_sym, :swaps_token)
          return render json: { error: "You are not authorized to do that!"}, status: :unauthorized
        end

        swaps = Secret::Transaction.swap.all
        total = 0
        swaps.each do |tx|
          total += tx.message[0]['value']['AmountENG'].to_f
        end
        total /= 10 ** 8.0
        return render json: { total: total.to_i }, status: :ok
      end
    end
  end
end
