class V1::CursorsController < ApplicationController
	before_action :setup_cursor 
	before_action :check_reader_perms
	before_action :check_admin_perms, :only => [:create, :destroy]

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

	def check_reader_perms
		render_unauthorized unless has_permission?(:reader, @message_cursor) || has_permission([:channel_admin, :subscription_admin], @channel)
	end 

	def check_admin_perms
		render_unauthorized unless has_permission?([:channel_admin, :subscription_admin], @channel)
	end

	def render_cursor_json(c)
		return c
	end

	def setup_cursor 
        @channel = Channel.autocreating_name_lookup(current_uid, params[:channel_id])
		if @channel.nil?
			render_unauthorized 
			return
		end

		@message_cursor = @channel.message_cursor.for_uid(current_uid).find(params[:id]) unless params[:id].nil?
	end
end