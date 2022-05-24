require "securerandom"
class V1::ChannelsController < ApplicationController
    before_action :setup_channel

    def create
    end 

	protected 

	def setup_channel
        @channel = Channel.autocreating_name_lookup(current_uid, params[:id])
        raise "Channel not found" if @channel.nil?
    end


end