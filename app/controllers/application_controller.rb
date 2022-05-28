class ApplicationController < ActionController::API
	protected 

    class << self
        # Must be set during startup
        attr_accessor :auth_plugin
    end

	def current_uid 
        @current_uid ||= begin
            tok = request.headers["Authorization"].to_s.split(/\s+/)[1]
            Rails.cache.fetch("token/#{tok}", :expires_in => 15.minutes) do 
                ApplicationController.auth_plugin.uid_for_token(tok)
            end
        end
    end

    def lookup_current_uid
    end

    def has_permission?(ctx, perm)
        return true
    end

	def interpret_boolean(val)
		ActiveModel::Type::Boolean.new.cast(val)
	end
end
