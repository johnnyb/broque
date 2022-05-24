class Channel < ApplicationRecord
	has_many :messages, ->{order(:id => :asc)}
	has_many :message_cursors 
	has_many :active_readings
	has_many :subscriptions

	scope :for_uid, ->(uid) { } # Not currently checking permissions

	def self.autocreating_name_lookup(uid, name)
		ch = for_uid(uid).where(:name => name).first
		return ch unless ch.nil?
		return nil unless has_permission?(uid, nil, :channel_create)
		return Channel.create!(:name => name, :owner_uid => uid)
	end
end