class ApplicationRecord < ActiveRecord::Base
	primary_abstract_class

	def has_permission?(uid, context, perm)
		self.class.has_permission?(uid, context, perm)
	end

	def self.has_permission?(uid, context, perm)
		return true
	end
end
