class Admin::Cosmos::FaucetsController < Admin::BaseController
  before_action :ensure_chain

  def init
    key_name = params[:cosmos_faucet][:name]
    password = SecureRandom.urlsafe_base64
    syncer = Cosmos::SyncBase.new(@chain)

    r = syncer.get_key( key_name )
    if !r.is_a?(Hash) && r =~ /not found/
      # we can create it
      begin
        seed = syncer.create_key( key_name, password )
        create_faucet(
          key_name: key_name,
          password: password,
          delay: params[:cosmos_faucet][:delay]
        )
        flash[:notice] = "Key '#{key_name}' created."
        flash[:warning] = "<strong>Seed Phrase - WRITE THIS DOWN</strong><br/><span class='technical'>#{seed}</span>"
      rescue
        Rails.logger.error "\n\nFAUCET COULD NOT BE CREATED\n#{$!.message}\n#{$!.backtrace.join("\n")}\n\n"
        flash[:error] = "Faucet could not be created. (#{$!.message})"
      end
    else
      flash[:error] = "Key name '#{key_name}' already exists."
    end

    redirect_to admin_cosmos_chain_path(@chain)
  end

  def create
    create_faucet(
      params.require(:cosmos_faucet)
            .permit(%i{ key_name delay password })
    )
    redirect_to admin_cosmos_chain_path(@chain)
  end

  def update
    @chain.faucet.assign_attributes params.require(:cosmos_faucet).permit(%i{ delay })
    if params.has_key?(:disable)
      @chain.faucet.assign_attributes disabled: true
    end
    if params.has_key?(:enable)
      @chain.faucet.assign_attributes disabled: false
    end

    if params.has_key?(:destroy)
      @chain.faucet.destroy
    else
      @chain.faucet.save
    end

    redirect_to admin_cosmos_chain_path(@chain)
  end

  def destroy
    @chain.faucet.try(:destroy)
    redirect_to admin_cosmos_chain_path(@chain)
  end

  def show
    @transactions = @chain.faucet.transactions
  end

  private

  def ensure_chain
    @chain = ::Cosmos::Chain.find_by( slug: params[:chain_id] )
  end

  def create_faucet( args )
    f = @chain.build_faucet( args )
    Cosmos::FaucetSyncService.new(@chain).sync_token_info!(f)
    flash[:notice] = "Account #{@chain.faucet.address} (key '#{@chain.faucet.key_name}') set up as faucet."
  end
end
