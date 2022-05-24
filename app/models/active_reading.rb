class ActiveReading < ApplicationRecord
	belongs_to :message_cursor 
	belongs_to :message

	scope :needs_rereading_for_cursor, ->(cursor){
		where(
			:message_cursor => cursor, 
			:completed_at => nil, 
			:expires_at => ..Time.now
		)
	}
end