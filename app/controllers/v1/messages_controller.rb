class V1::MessagesController < ApplicationController
	before_action :setup_message_cursor

	def pending_count
		count = Message.available_to_cursor(@message_cursor).count 
		render :json => { :count => count }
	end

    def index
		raise "Cursor not found" if @message_cursor.nil?
		should_update_cursor = true
		autocomplete = interpret_boolean(params[:autocomplete])
		max_messages = params[:max_messages] || @message_cursor.default_max_messages

        MessageCursor.transaction do
			@message_cursor.lock!

			# Find relevant messages
            @messages = Message.available_to_cursor(@message_cursor).limit(max_messages)

			# Mark them as being read
			if autocomplete
				# On autocomplete, if there is an outstanding reading for this message, delete it
				@messages.each do |msg|
					reading = @message_cursor.active_readings.where(
						:message => msg
					).delete_all
				end
			else
				# On non-autocomplete, create an "active reading" for each message
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

	# Search all messages in the channel
	def search
		msgs = @channel.messages 
		max_messages = params[:max_messages] || 100 
		offset = params[:offset]
		(params[:metadata] || {}).each do |k, v|
			msgs = msgs.having_metadata(k, v)
		end
		origref = params[:message_origination_reference]
		if origref.present?
			msgs = msgs.where(:message_origination_reference => origref)
		end

		# FIXME do something with begin/end date and id
		# sdate = params[:since]
		# edate = params[:until]

		if params[:publisher_uid].present?
			msgs = msgs.where(:publisher_uid => params[:publisher_uid])
		end

		if offset.present?
			msgs = msgs.offset(offset.to_i)
		end 
		msgs = msgs.limit(max_messages)

		render :json => render_message_json(msgs)
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
		msg = @message_cursor.messages.for_system_identifier(params[:id]).first
		unless msg.nil?
			@message_cursor.active_readings.where(:message_id => msg.id).delete_all
		end
	end

    def create
        Message.transaction do
            @message = @channel.messages.find_or_create_by(
				# This is the client's non-duplication ID, unique for the channel (auto-created by us if not supplied)
                :message_origination_reference => (params[:message_origination_reference] || SecureRandom.uuid), 
            ) do |rec|
				rec.message = params[:message]
				rec.publisher_uid = current_uid 
				# This is our internal non-duplication ID, unique for whole system
				rec.message_reference = SecureRandom.uuid

				(params[:metadata] || {}).each do |k, v|
					rec.message_metadata.build(
						:key => k, 
						:value => v
					)
				end	
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
			@message = @channel.messages.for_system_identifier(params[:id]).first
		end
    end

	def render_message_json(msg, opts = {})
		return msg.as_json(:only => [:id, :publisher_uid, :created_at, :updated_at, :message_reference, :message_origination_reference]) if opts[:headers_only]
		return msg.as_json(:methods => [:metadata])
	end
end