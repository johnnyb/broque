class V1::MessagesController < ApplicationController
	before_action :setup_message_cursor

    def index
		raise "Cursor not found" if @message_cursor.nil?
		should_update_cursor = true
		autoremove = interpret_boolean(params[:autoremove])
		max_messages = params[:max_messages] || @message_cursor.default_max_messages
        MessageCursor.transaction do
			@message_cursor.lock!

            @messages = Message.available_to_cursor(@message_cursor).limit(max_messages)

			unless autoremove
				@messages.each do |msg|
					@message_cursor.active_readings.create!(
						:message => msg,
						:expires_at => Time.now + @message_cursor.default_read_timeout
					)
				end
			end
        end
		render :json => render_message_json(@messages)
    end

	def show 
		return :json => render_message_json(@message)
	end

	def complete
		@message_cursor.active_readings.where(:message_id => params[:message_id])
	end

    def create
        Message.transaction do
            @message = @channel.message.create!(
                :message_reference => SecureRandom.uuid,
                :message_origination_reference => (params[:message_origination_reference] || SecureRanodm.uuid),
                :publisher_uid => current_uid,
                :message => params[:message] || request.raw_post
            )
            params[:attributes].each do |k, v|
                @message.message_attributes.create!(
                    :key => k, 
                    :value => v
                )
            end
        end 

        render :json => render_message_json(@message, :headers_only => true)
    end

	protected 

	def setup_message_cursor
		@channel = Channel.autocreating_name_lookup(current_uid, params[:channel_id])
        raise "Channel not found" if @channel.nil?

		if params[:cursor_id].present?
			@message_cursor = @channel.message_cursors.for_uid(current_uid).find(params[:cursor_id])
		elsif params[:subscription_id].present?
			@subscription = Subscription.autocreating_name_lookup(@channel, current_uid, params[:subscription_id])
			@message_cursor = @subscription.default_message_cursor 
		end
		raise "Cursor not found" if @message_cursor.nil?

		if params[:id].present?
			@message = @message_cursor.channel.messages.find(params[:id])
		end
    end

	def render_message_json(msg, opts = {})
		return msg.as_json(:only => [:id, :publisher_uid, :created_at, :updated_at]) if opts[:headers_only]
		return msg.as_json
	end
end