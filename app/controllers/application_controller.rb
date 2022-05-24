class ApplicationController < ActionController::API
	protected 

	def current_uid 
        "none"
    end

    def has_permission?(ctx, perm)
        return true
    end

	def interpret_boolean(val)
		ActiveModel::Type::Boolean.new.cast(val)
	end
end
