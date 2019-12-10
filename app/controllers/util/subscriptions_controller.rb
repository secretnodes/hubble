class Util::SubscriptionsController < ApplicationController
  before_action :set_chain_and_validator

  def index
    unless current_user
      redirect_to new_user_path
      return
    end
    @subscription = current_user.alert_subscriptions.where( alertable: @validator ).first
    page_title @chain.network_name, @chain.name, "Event Subscription for #{@validator.name_and_owner}"
  end

  def create
    @subscription = current_user.alert_subscriptions.where( alertable: @validator ).first
    @subscription ||= current_user.alert_subscriptions.where( alertable: @validator ).new

    @subscription.assign_attributes sanitize_sub_params

    existed = @subscription.persisted?
    if !existed
      # mark the user as having received a digest yesterday
      # and an alert just this moment so they don't get old events on next sync
      @subscription.assign_attributes last_daily_at: 1.day.ago.end_of_day, last_instant_at: Time.now.utc
    end

    if @subscription.save
      if existed
        flash[:notice] = "Subscription updated!"
      else
        flash[:notice] = "Subscribed to events for this validator!"
      end
      redirect_to namespaced_path( 'validator_subscriptions', @validator )
    else
      if !@subscription.subscribes_to_something?
        @subscription.destroy
        flash[:notice] = "No alerts selected. Subscription removed."
        redirect_to namespaced_path( 'validator_subscriptions', @validator )
      else
        render :index
      end
    end
  end

  private

  def sanitize_sub_params
    params[:alert_subscription] ||= ActionController::Parameters.new({})
    kinds_hash = params[:alert_subscription][:event_kinds] || {}
    kinds = kinds_hash.keys.select { |k| kinds_hash[k] == 'on' }
    params[:alert_subscription][:event_kinds] = kinds

    if params[:alert_subscription][:data]
      if pc = params[:alert_subscription][:data][:percent_change]
        params[:alert_subscription][:data][:percent_change] = pc.to_f
      end
    end

    p = params.fetch(:alert_subscription, {}).permit(
      %w{ wants_daily_digest },
      event_kinds: [],
      data: valid_subscription_data_fields
    )

    p
  end

  def valid_subscription_data_fields
    event_kinds = params[:alert_subscription][:event_kinds] rescue []
    return [] if event_kinds.empty?

    defn = @chain.validator_event_defs.find { |defn| defn['kind'].in?(event_kinds) }
    # Rails.logger.debug "DATA KIND: #{defn.inspect}"

    case defn['kind']
    when 'voting_power_change' then %i{ percent_change }
    else nil
    end
  end

  def set_chain_and_validator
    @chain = params[:network].titleize.constantize::Chain.find_by( slug: params[:chain_id] )
    @namespace = @chain.namespace
    @validator = @chain.validators.find_by( address: params[:validator_id] )
  end

end
