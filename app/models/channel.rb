class Channel < ApplicationRecord
	has_many :messages, ->{order(:id => :asc)}
	has_many :message_cursors 
	has_many :active_readings
	has_many :subscriptions
	has_many :permissions, :as => :permission_on

	# NOTE - Only check permissions on creation
	def self.autocreating_name_lookup(uid, name)
		ch = where(:name => name).first
		return ch unless ch.nil?
		return nil unless has_permission?(uid, [:channel_admin, :global_admin])
		return Channel.create!(
			:name => name, 
			:owner_uid => uid,
			:permission_required => Permission.global_permission_object.permission_required?,
			:authentication_required => Permission.global_permission_object.authentication_required?
		)
	end

	def self.clean_expired_messages!
		# Delete fully expired messages
		Channel.where(:expire_messages => true).each do |ch|
			# Kill all messages **and** active reads which are past the forced expiration time
			if (ch.force_message_expiration_time || 0) > 0
				ch.messages.where(:created_at => ..(Time.now - ch.force_message_expiration_time.seconds)).destroy_all
			end

			# Find the minimum ID of all readers
			min_id = ch.message_cursors.minimum(:last_message_id)
			# Delete everything below that number that doesn't have an active read associated (whether DLQ or not)
			ch.messages.where(:id => ..min_id).and(ch.messages.where.not(ActiveReading.all.select(:message_id).arel.exists)).delete_all # Don't have to destroy because there are no associated records!
			ch.messages.where(:id => ..min_id).and(where.not(:id => ActiveReading.all))
		end
	end
end