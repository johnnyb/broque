class V1::CursorsController < ApplicationController
	before_action :setup_cursor 

	def create
		@message_cursor = @channel.message_cursors.create!(
			:originator_uid => current_uid,
			:last_message_id => last_message_id
		)
		render :json => @message_cursor
	end

	def reset 
		MessageCursor.transaction do
			@message_cursor.lock!
			@message_cursor.update!(
				:last_message_id => params[:last_message_id]
			)
		end
	end

	protected

	def setup_cursor 
        @channel = Channel.autocreating_name_lookup(current_uid, params[:channel_id])
        raise "Channel not found" if @channel.nil?

		@message_cursor = @channel.message_cursor.for_uid(current_uid).find(params[:id]) unless params[:id].nil?
	end
end