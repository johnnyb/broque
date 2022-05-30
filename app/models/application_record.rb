class ApplicationRecord < ActiveRecord::Base
	primary_abstract_class

	def has_permission?(uid, perm, obj = nil)
		self.class.has_permission?(uid, perm, obj)
	end

	def self.has_permission?(uid, perm, obj = nil)
		Permission.has_permission?(uid, perm, obj)
	end
end
