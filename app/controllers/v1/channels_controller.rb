require "securerandom"
class V1::ChannelsController < ApplicationController
    before_action :setup_channel

    def create
		update
    end 

	def update 
		@channel.update!(params.slice(
			"expire_messages", 
			"force_message_expiration_time", 
			"default_max_reads", 
			"default_read_timeout"
		))
		render :json => @channel
	end

	protected 

	def setup_channel
        @channel = Channel.autocreating_name_lookup(current_uid, params[:id])
        raise "Channel not found" if @channel.nil?
    end


end