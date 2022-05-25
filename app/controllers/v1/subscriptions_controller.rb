class V1::SubscriptionsController < ApplicationController
	before_action :setup_channel 

    def create
		update
        Subscription.transaction do 
			if params[:last_message_id].present?
				@subscription.last_message_id = params[:last_message_id]
				@subscription.save!
			end
        end
        render :json => render_subscription_json(@subscription)
    end

	def update
		@subscription.default_message_cursor.update!(params.slice(
			"last_message_id",
			"default_max_reads",
			"default_read_timeout"
		))
		render :json => @subscription
	end

	def destroy
		MessageCursor.transaction do
			@subscription.destroy
		end
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
		return subscr.as_json().merge(subscr.default_message_cursor.as_json)
	end

	def setup_channel
        @channel = Channel.autocreating_name_lookup(current_uid, params[:channel_id])
        raise "Channel not found" if @channel.nil?

		@subscription = Subscription.autocreating_name_lookup(@channel, current_uid, params[:id])
		raise "Subscription not found" if @subscription.nil?
    end
end