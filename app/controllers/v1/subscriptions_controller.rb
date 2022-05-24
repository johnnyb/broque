class V1::SubscriptionsController < ApplicationController
	before_action :setup_channel 

    def create
        Subscription.transaction do 
			if params[:last_message_id].present?
				@subscription.last_message_id = params[:last_message_id]
				@subscription.save!
			end
        end
        render :json => render_subscription_json(@subscription)
    end

	def show 
		render :json => render_subscription_json(@subscription)
	end

	def reset 
		@message_cursor = @subscription.default_message_cursor
		MessageCursor.transaction do
			@message_cursor.lock!
			@message_cursor.reset_to!(params[:last_message_id])
		end

		render :json => render_subscription_json(@subscription)
	end

	protected

	def render_subscription_json(subscr)
		return subscr.as_json(:include => {:default_message_cursor => {}})
	end

	def setup_channel
        @channel = Channel.autocreating_name_lookup(current_uid, params[:channel_id])
        raise "Channel not found" if @channel.nil?

		@subscription = Subscription.autocreating_name_lookup(@channel, current_uid, params[:id])
		raise "Subscription not found" if @subscription.nil?
    end
end