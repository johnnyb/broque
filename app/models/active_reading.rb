class ActiveReading < ApplicationRecord
	belongs_to :message_cursor 
	belongs_to :message

	scope :needs_rereading_for_cursor, ->(cursor){
		select(:message_id).where(
			:died => false,
			:message_cursor => cursor,
			:expires_at => ..Time.now
		)
	}

	# Note - it is not officially in the DLQ until *BOTH* died_at is set *and* expires_at is past
	scope :dead, ->{where(:died => true, :expires_at => ..Time.now)}
end