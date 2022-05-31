class Subscription < ApplicationRecord
	belongs_to :channel
	belongs_to :default_message_cursor, :class_name => "MessageCursor", :foreign_key => "default_message_cursor_id", :dependent => :destroy

	delegate :authentication_required?, :to => :channel
	delegate :permission_required?, :to => :channel

	# NOTE - Only check permissions on creation
	def self.autocreating_name_lookup(channel, uid, name)
		subscription = channel.subscriptions.where(:name => name).first
		return subscription unless subscription.nil?
		return nil unless has_permission?(uid, [:subscription_create, :channel_admin], channel)

		last_message_id = channel.messages.last.try(:id)
		message_cursor = channel.message_cursors.create!(
			:originator_uid => uid,
			:last_message_id => last_message_id
		)
		subscription = channel.subscriptions.create!(
			:subscriber_uid => uid,
			:name => name,
			:default_message_cursor => message_cursor,
		)
		return subscription
	end

	def as_json(opts = {})
		data = super(opts)
		data["id"] = data["id"].to_s 
		data["channel_id"] = data["channel_id"].to_s if data["channel_id"].present?

		return data
	end
end