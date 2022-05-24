class V1::SubscriptionsController < ApplicationController
	before_action :setup_channel 

    def create
        Subscription.transaction do 
			last_message_id = params[:starting_from_message_id] || @channel.messages.last.try(:id)
            @message_cursor = @channel.message_cursors.create!(
                :originator_uid => current_uid,
				:last_message_id => last_message_id
            )
            @subscription = @channel.subscriptions.create!(
                :subscriber_uid => current_uid,
                :name => params[:name],
                :default_message_cursor => @message_cursor,
            )
        end
        render :json => @subscription
    end

	def show 
	end

	protected

	def setup_channel
        @channel = Channel.autocreating_name_lookup(current_uid, params[:channel_id])
        raise "Channel not found" if @channel.nil?

		@subscription = Subscription.autocreating_name_lookup(@channel, current_uid, params[:subscription_id])
		raise "Subscription not found" if @subscription.nil?
    end
end