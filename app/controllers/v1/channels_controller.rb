class V1::ChannelsController < ApplicationController
    before_action :setup_channel

    def configure
    end 

    def read
        MessageCursor.transaction do
            if params[:message_cursor_id].present?
                @message_cursor = @channel.message_cursors.for_uid(current_uid).find(params[:message_cursor_id])
            elsif params[:subscription].present?
                @subscription = @channel.subscriptions.for_uid(current_uid).find(params[:subscription])
                @message_cursor = @subscription.default_message_cursor 
            end
            raise "Cursor not found" if @message_cursor.nil?

            max_messages = params[:max_messages]
            @channel.messages.where("id > ?")

        end
    end

    def publish
        Message.transaction do
            @message = @channel.message.create!(
                :message_reference => SecureRandom.uuid,
                :message_origination_reference => (params[:message_origination_reference] || SecureRanodm.uuid)
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

        render :json => @message.as_json(:only => [:id, :publisher_uid, :created_at, :updated_at])
    end

    def subscribe
        Subscriber.transaction do 
            @message_cursor = @channel.message_cursors.create!(
                :originator_uid => current_uid
            )
            @subscriber = @channel.subscribers.create!(
                :subscriber_uid => current_uid,
                :name => params[:name],
                :default_message_cursor => @message_cursor,
            )
        end
        render :json => @subscriber
    end

    def setup_channel
        @channel = Channel.for_uid(current_uid).where(:name => params[:id]).first
        if @channel.nil?
            if has_permission?(:channel_create)
                @channel = Channel.create!(:name => params[:id])
            end
        end
        raise "Channel not found" if @channel.nil?            
    end

end