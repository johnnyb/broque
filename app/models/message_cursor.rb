class MessageCursor < ApplicationRecord
	belongs_to :channel

	has_many :active_readings
	# NOTE - last_message_id generally refers to a actual message, but we aren't going to do a belongs_to because we don't actually care

	scope :for_uid, ->(uid) { } # Not currently checking permissions

	def default_max_messages
		100
	end

	def default_read_timeout
		return 30.seconds
	end

	def reset_to!(msg_id)
		self.last_message_id = msg_id 
		self.save!
		ActiveReading.where(:message_cursor => self, :message_id => (msg_id || 0)..).delete_all
	end

	def as_json(opts = {})
		data = super(opts)
		data["id"] = data["id"].to_s 
		data["channel_id"] = data["channel_id"].to_s if data["channel_id"].present?

		return data
	end
end