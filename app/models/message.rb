class Message < ApplicationRecord
	belongs_to :channel 
	has_many :message_metadata
	has_many :active_readings, :dependent => :delete_all

	scope :available_to_cursor, ->(cursor){
		min_message_id = (cursor.last_message_id || 0) + 1
		where(
			:channel => cursor.channel,
			:id => min_message_id.., # range
		).or(where(:id => ActiveReading.needs_rereading_for_cursor(cursor))).order(:id => :asc)
	}

	scope :for_system_identifier, ->(ident){
		where(:id => ident).or(where(:message_reference => ident))
	}

	# Force-stringify IDs
	def as_json(opts = {})
		data = super(opts)
		data["id"] = data["id"].to_s 
		data["channel_id"] = data["channel_id"].to_s if data["channel_id"].present?

		return data
	end

	def metadata
		data = {}
		message_metadata.each do |mm|
			data[mm.key] = mm.value
		end
		return data
	end
end