# Permission List:
#  * GLOBAL
#    * :channel_admin
#    * :global_admin
#  * CHANNEL
#    * :channel_admin
#    * :subscription_admin
#    * :writer
#  * SUBSCRIPTION / MESSAGE_CURSOR
#    * :reader

class Permission < ApplicationRecord
	belongs_to :permission_on, :polymorphic => true, :optional => true

	def self.has_permission?(uid, perm, obj = nil)
		perm_obj = obj == nil ? Permission.global_permission_object : obj

		return true unless perm_obj.authentication_required?
		return false if uid.blank?
		return true unless perm_obj.permission_required?
		return true if perm_obj.owner_uid == uid
		
		search = Permission.where(:uid => uid, :permission => perm, :permission_on => obj)
		return !search.empty?
	end

	#### Use ENV Vars for Global Permissioning ####
	def self.global_permission_object
		@gpo ||= self
		return @gpo
	end

	# Mostly used for testing
	def self.global_permission_object=(val)
		@gpo = val
	end

	def self.authentication_required?
		ActiveModel::Type::Boolean.new.cast(ENV["AUTH_REQUIRED"])
	end 

	def self.permission_required?
		return owner_uid.present?
	end

	def self.owner_uid
		return ENV["AUTH_MASTER_BOOTSTRAP"]
	end

end