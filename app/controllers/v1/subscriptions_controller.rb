class V1::SubscriptionsController < ApplicationController
	before_action :setup_subscription
	before_action :check_subscription_admin_perms, :only => [:create, :update, :destroy]
	before_action :check_subscription_reader_perms

    def create
		update
    end

	def update
		@subscription.default_message_cursor.update!(params.slice(
			"last_message_id",
			"default_max_reads",
			"default_read_timeout"
		).permit!)
        render :json => render_subscription_json(@subscription)
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

	def check_subscription_admin_perms
		raise "Invalid user" unless has_permission?([:channel_admin, :subscription_admin], @channel)
	end

	def check_subscription_reader_perms 
		raise "Invalid user" unless has_permission?([:channel_admin, :subscription_admin], @channel) || has_permission([:reader], @subscription)
	end

	def render_subscription_json(subscr)
		return subscr.as_json().merge(subscr.default_message_cursor.as_json)
	end

	def setup_subscription
        @channel = Channel.autocreating_name_lookup(current_uid, params[:channel_id])
		if @channel.nil?
			render_unauthorized
			return
		end

		@subscription = Subscription.autocreating_name_lookup(@channel, current_uid, params[:id])
		if @subscription.nil?
			render_unauthorized
			return
		end
    end
end