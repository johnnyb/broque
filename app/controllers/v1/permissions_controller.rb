class V1::PermissionsController < ApplicationController
	before_action :setup_permission_object
	before_action :check_permission_permission

	def index 
		Permission.where(:permission_on => @permission_on)
	end 

	def create 
		Permission.find_or_create_by!(:permission_on => @permission_on, :uid => params[:uid], :permission => params[:permission])
		index
	end 

	def delete
		Permission.where(:permission_on => @permission_on, :uid => params[:uid], :permission => params[:permission]).delete_all
		render :nothing => true
	end

	protected

	def setup_permission_object
		if params[:channel_id].blank?
			@permission_on = nil 
			@global_permission = true
			return 
		end

		@channel = Channel.autocreating_name_lookup(current_uid, params[:channel_id])
		return render_unauthorized if @channel.nil?

		if params[:subscription_id].present?
			@subscription = Subscription.autocreating_name_lookup(@channel, current_uid, params[:subscription_id])
			return render_unauthorized if @subscription.nil?
			@permission_on = @subscription

		elsif params[:cursor_id].present?
			@message_cursor = @channel.message_cursor.for_uid(current_uid).find(params[:cursor_id])
			return render_unauthorized if @message_cursor.nil?
			@permission_on = @message_cursor
		else
			@permission_on = @channel
		end
	end

	def check_permission_permission
		if @global_permission
			render_unauthorized unless has_permission?([:global_admin])
			return 
		end

		return if has_permission?([:channel_admin], @channel)
		return if @subscription.present? && has_permission?(:subscription_admin, @subscription)
		render_unauthorized
	end
end