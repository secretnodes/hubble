class WalletsController < ApplicationController
  layout 'account'
  load_and_authorize_resource

  def index
    @chain = Secret::Chain.primary
    @wallet_types = current_user.wallets.group_by(&:wallet_type).map { |k, v| [k, v.collect { |a| [a.public_address, a.id] }] }
    @wallets = current_user.wallets.all

    @default_wallet = current_user.wallets.where(default_wallet: true).first
    @validators = @chain.validators.all
  end

  def update
    old_default = current_user.wallets.find_by_default_wallet true

    if old_default.present?
      if old_default.id != params[:id].to_i
        new_default = current_user.wallets.find params[:id]
        if old_default.update(default_wallet: false) && new_default.update(default_wallet: true)
          flash[:notice] = "You successfully updated your default wallet."
        end
      else
        flash[:error] = "Your default wallet did not change."
      end
    else
      new_default = current_user.wallets.find params[:id]
      flash[:notice] = "You successfully updated your default wallet." if new_default.update(default_wallet: true)
    end
    redirect_back(fallback_location: wallets_path)
  end
end