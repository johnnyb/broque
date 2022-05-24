class ActiveReading < ApplicationRecord
	belongs_to :message_cursor 
	belongs_to :message

	scope :needs_rereading_for_cursor, ->(cursor){
		select(:message_id).where(
			:message_cursor => cursor,
			:expires_at => ..Time.now
		)
	}
end