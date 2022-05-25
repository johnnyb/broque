class V1::MessagesController < ApplicationController
	before_action :setup_message_cursor

    def index
		raise "Cursor not found" if @message_cursor.nil?
		should_update_cursor = true
		autoremove = interpret_boolean(params[:autoremove])
		max_messages = params[:max_messages] || @message_cursor.default_max_messages

        MessageCursor.transaction do
			@message_cursor.lock!

			# Find relevant messages
            @messages = Message.available_to_cursor(@message_cursor).limit(max_messages)

			# Mark them as being read
			if autoremove
				# On autoremove, if there is an outstanding reading for this message, delete it
				@messages.each do |msg|
					reading = @message_cursor.active_readings.where(
						:message => msg
					).delete_all
				end
			else
				# On non-autoremove, create an "active reading" for each message
				@messages.each do |msg|
					reading = @message_cursor.active_readings.find_or_create_by(
						:message => msg
					)
					reading.max_reads = @message_cursor.default_max_reads
					reading.read_count += 1
					reading.expires_at = Time.now + @message_cursor.default_read_timeout

					# Check for message death
					if (reading.max_reads || 0) > 0
						# NOTE - this doesn't technically kill the message until we hit expires_at
						if reading.read_count == reading.max_reads 
							reading.died = true
						end
					end

					reading.save!
				end
			end

			# Get the rendered data
			message_data = render_message_json(@messages)

			# Update the cursor
			if message_data.size > 0
				tmp_id = message_data.last["id"].to_i
				if (@message_cursor.last_message_id || 0) < tmp_id
					@message_cursor.update!(
						:last_message_id => tmp_id
					)
				end 
			end

			# Send data
			render :json => message_data
        end
    end

	def dead
		last_message_id = params[:last_message_id] || 0
		max_messages = params[:max_messages] || @message_cursor.default_max_messages
		@dead_messages = @message_cursor.active_readings.dead.where(:message_id => last_message_id..).limit(max_messages)
		render :json => @dead_messages
	end

	def clear_dlq
		MessageCursor.transaction do
			@message_cursor.lock!
			@message_cursor.active_readings.dead.delete_all
		end
	end

	def redrive_dlq
		MessageCursor.transaction do
			@message_cursor.lock!
			@message_cursor.active_readings.dead.update_all(:died => false, :read_count => 0)
		end
	end

	def show 
		render :json => render_message_json(@message)
	end

	def complete
		@message_cursor.active_readings.where(:message_id => params[:message_id]).destroy_all
	end

    def create
        Message.transaction do
            @message = @channel.messages.create!(
                :message_reference => SecureRandom.uuid,
                :message_origination_reference => (params[:message_origination_reference] || SecureRandom.uuid),
                :publisher_uid => current_uid,
                :message => params[:message] || request.raw_post
            )
            (params[:metadata] || {}).each do |k, v|
                @message.message_metadata.create!(
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

		if params[:id].present?
			@message = @channel.messages.find(params[:id])
		end
    end

	def render_message_json(msg, opts = {})
		return msg.as_json(:only => [:id, :publisher_uid, :created_at, :updated_at]) if opts[:headers_only]
		return msg.as_json(:methods => [:metadata])
	end
end