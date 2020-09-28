class Common::EventsController < Common::BaseController
  before_action :ensure_chain

  def index
    @page = (params[:page] || 1).to_i
    @offset = @chain.class::EVENTS_PAGE_SIZE * (@page - 1)
    events = get_events

    if params[:validator]
      validators = @chain.namespace::Validator.where( address: params[:validator] )
      if validators.present?
        validator_ids = validators.pluck(:id)
        @validator = validators.select { |val| val.chain_id == @chain.id }.first
        events = events.select{ |e| validator_ids.include?(e.validatorlike_id) }
        page_title @chain.network_name, @chain.name, "Events for #{@validator.long_name}"
        meta_description "Validator events for #{@validator.name_and_owner} on #{@chain.network_name} - #{@chain.name}"
      end
    else
      page_title @chain.network_name, @chain.name, 'Events'
      meta_description "Validator events for #{@chain.network_name} - #{@chain.name}"
    end

    @total = events.count
    @events = events.paginate(page: params[:page], per_page: @chain.class::EVENTS_PAGE_SIZE)
  end

  def show
    @event = params[:type].constantize.find params[:id]

    if @event.type.include?("Common::ValidatorEvents")
      @validator = @event.validatorlike
    end
    page_title @chain.network_name, @chain.name, @event.page_title
    meta_description @event.page_title
  end

  def events_table
    @page = (params[:page] || 1).to_i
    events = get_events

    if params[:validator]
      validators = @chain.namespace::Validator.where( address: params[:validator] )
      if validators.present?
        validator_ids = validators.pluck(:id)
        @validator = validators.select { |val| val.chain_id == @chain.id }.first
        events = events.select{ |e| validator_ids.include?(e.validatorlike_id) }
      end
    end

    @total = events.count
    @events = events.paginate(page: @page, per_page: @chain.class::EVENTS_PAGE_SIZE)

    render partial: 'events_table', locals: { events: @events, page: @page, total: @total }
  end

  private

  def get_events
    chain_ids = @chain.namespace::Chain.where(testnet: @chain.testnet?).pluck(:id)
    events = (Common::Event.where(chainlike_id: chain_ids, chainlike_type: @chain.class.to_s) + 
      Common::ValidatorEvent.where(chainlike_id: chain_ids, chainlike_type: @chain.class.to_s)).sort_by { |e| -e.timestamp.to_i }
  end
end
