class V1::SubscriptionsController < ApplicationController
	before_action :setup_channel 

    def create
        Subscription.transaction do 
			
        end
        render :json => @subscription
    end

	def show 
	end

	def reset 
		@message_cursor = @subscription.default_message_cursor
		MessageCursor.transaction do
			@message_cursor.lock!
			@message_cursor.reset_to!(params[:last_message_id])
		end
	end

	protected

	def setup_channel
        @channel = Channel.autocreating_name_lookup(current_uid, params[:channel_id])
        raise "Channel not found" if @channel.nil?

		@subscription = Subscription.autocreating_name_lookup(@channel, current_uid, params[:id])
		raise "Subscription not found" if @subscription.nil?
    end
end