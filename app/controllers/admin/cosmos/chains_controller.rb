class Admin::Cosmos::ChainsController < Admin::BaseController

  def new
    @chain = ::Cosmos::Chain.new
  end

  def create
    @chain = ::Cosmos::Chain.create(
      params.require(:cosmos_chain).permit( %i{
        name slug token_denom token_factor
        primary testnet gaiad_host disabled
      } )
    )
    if @chain.primary?
      ::Cosmos::Chain.where.not( id: @chain.id ).update_all primary: false
    end
    redirect_to admin_cosmos_chain_path(@chain)
  end

  def show
    @chain = ::Cosmos::Chain.find_by slug: params[:id]
  end

  def update
    @chain = ::Cosmos::Chain.find_by slug: params[:id]

    updates = params.require(:cosmos_chain).permit(
      %i{
        token_denom token_factor
        gaiad_host rpc_port lcd_port primary disabled
        validator_event_defs
      },
      validator_event_defs: %i{ unique_id kind n m height }
    )

    if updates.has_key?(:validator_event_defs)
      # sanitize event defs to an array
      updates[:validator_event_defs] = updates[:validator_event_defs].values

      # sanitize n, m, and height fields to integers
      params_defns = updates[:validator_event_defs].index_by { |defn| defn['unique_id'] }
      existing_defns = @chain.validator_event_defs.index_by { |defn| defn['unique_id'] }
      new_defns = []

      params_defns.keys.each do |defn_id|
        new_defn = if existing_defns.keys.include?(defn_id)
          existing_defns[defn_id].merge params_defns[defn_id]
        else
          params_defns[defn_id]
        end
        new_defn['n'] = new_defn['n'].to_i if new_defn.has_key?('n')
        new_defn['m'] = new_defn['m'].to_i if new_defn.has_key?('m')
        new_defn['height'] = new_defn.has_key?('height') ? new_defn['height'].to_i : 0

        new_defns << new_defn
      end

      updates[:validator_event_defs] = new_defns
    end

    @chain.update_attributes updates

    # make sure only 1 chain is primary
    if @chain.primary?
      ::Cosmos::Chain.where.not( id: @chain.id ).update_all primary: false
    end

    flash[:notice] = "Chain info updated."
    redirect_to admin_cosmos_chain_path(@chain)
  end

  def destroy
    @chain = ::Cosmos::Chain.find_by slug: params[:id]
    @chain.destroy
    flash[:notice] = 'Chain deleted. All data purged.'
    redirect_to admin_root_path
  end
end
