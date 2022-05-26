class V1::CursorsController < ApplicationController
	before_action :setup_cursor 

	def create
		@message_cursor = @channel.message_cursors.create!(
			:originator_uid => current_uid,
			:last_message_id => last_message_id
		)
		render :json => render_cursor_json(@message_cursor)
	end

	def update 
		@message_cursor.update!(params.slice(
			"last_message_id",
			"default_max_reads",
			"default_read_timeout"
		).permit!)

		render :json => render_cursor_json(@message_cursor)
	end

	def destroy
		MessageCursor.transaction do
			@message_cursor.destroy
		end
	end

	def reset 
		MessageCursor.transaction do
			@message_cursor.lock!
			@message_cursor.reset_to!(params[:last_message_id])
		end
		render :json => render_cursor_json(@message_cursor)
	end

	protected

	def render_cursor_json(c)
		return c
	end

	def setup_cursor 
        @channel = Channel.autocreating_name_lookup(current_uid, params[:channel_id])
        raise "Channel not found" if @channel.nil?

		@message_cursor = @channel.message_cursor.for_uid(current_uid).find(params[:id]) unless params[:id].nil?
	end
end