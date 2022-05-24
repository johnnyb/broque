class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class


	def has_permission?(uid, context, perm)
		return true
	end
end
