class Cosmos::FaucetTransactionsController < Cosmos::BaseController
  include AdminHelper

  before_action :ensure_chain
  before_action :ensure_faucet

  def create
    # valid captcha?
    if !valid_captcha?
      flash[:error] = 'Captcha verification failed. Please try again.'
      redirect_to params[:fail_dest]
      return
    end

    address = params[:fund_this_address].strip

    if current_admin || @faucet.can_fund?( user: current_user, address: address, ip: current_ip )
      tr = @faucet.transactions.create(
        user: current_user,
        address: address,
        ip: current_ip,
        amount: @faucet.class::AMOUNT,
        denomination: params[:denomination]
      )
      if tr.valid?
        redirect_to params[:ok_dest].sub('TRANSACTION-ID', tr.id)
      else
        flash[:error] = tr.errors.full_messages.join("\n")
        redirect_to params[:fail_dest]
      end
    else
      recent = @faucet.latest_funding( user: current_user, address: address, ip: current_ip )
      if recent
        # puts "\n\n#{Time.now.utc}\n#{recent.created_at}\n#{recent.created_at + @faucet.delay.seconds}\n\n"
        how_long = distance_of_time_in_words( recent.created_at + @faucet.delay.seconds, Time.now.utc, true, highest_measures: 2 )
        flash[:error] = "Please wait #{how_long} before requesting more funding."
      else
        flash[:error] = "An unknown error occurred trying to create that transaction. Sorry!"
      end
      redirect_to params[:fail_dest]
    end
  end

  def show
    @transaction = @faucet.transactions.find_by( id: params[:id] )
    raise ActiveRecord::RecordNotFound unless @transaction
  end

  private

  def ensure_chain
    @chain = Cosmos::Chain.find_by( slug: params[:chain_id] )
  end

  def ensure_faucet
    @faucet = @chain.faucet
    raise ActiveRecord::RecordNotFound unless @faucet
  end

  def valid_captcha?
    begin
      req = Curl.post 'https://www.google.com/recaptcha/api/siteverify',
                      secret: Rails.application.secrets.recaptcha[:secret],
                      response: params['g-recaptcha-response'],
                      remoteip: current_ip
      res = JSON.parse( req.body_str )
      return res['success']
    rescue
      Rails.logger.error $!.message
      return false
    end
  end

end
