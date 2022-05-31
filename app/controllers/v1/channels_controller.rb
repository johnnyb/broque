require "securerandom"
class V1::ChannelsController < ApplicationController
    before_action :setup_channel
	before_action :check_channel_perms

    def create
		update
    end 

	def update 
		@channel.update!(params.slice(
			"expire_messages", 
			"force_message_expiration_time", 
			"default_max_reads", 
			"default_read_timeout"
		).permit!)
		render :json => @channel
	end

	def show 
		render :json => @channel
	end

	protected 

	def check_channel_perms
		render_unauthorized unless has_permission?(:channel_admin, @channel)
	end

	def setup_channel
        @channel = Channel.autocreating_name_lookup(current_uid, params[:id])
        render_unauthorized if @channel.nil?
    end
end