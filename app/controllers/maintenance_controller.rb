class MaintenanceController < ApplicationController
	def periodic_maintenance
		# Delete fully expired messages
		Channel.where(:expire_messages => true).each do |ch|
			if (ch.force_message_expiration_time || 0) > 0
				# Kill all messages **and** active reads which are past the forced expiration time
				ch.messages.where(:created_at => ..(Time.now - ch.force_message_expiration_time.seconds)).destroy_all

				# Find the minimum ID of all readers
				min_id = ch.message_cursors.minimum(:last_message_id)
				# Delete everything below that number that doesn't have an active read associated (whether DLQ or not)
				ch.messages.where(:id => ..min_id).and(ch.messages.where.not(ActiveReading.all.select(:message_id).arel.exists)).delete_all # Don't have to destroy because there are no associated records!
				ch.messages.where(:id => ..min_id).and(where.not(:id => ActiveReading.all))
			end
		end
	end
end