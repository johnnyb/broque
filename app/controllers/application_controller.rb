class ApplicationController < ActionController::API
	protected 

    ### Auth-related
    class << self
        # Must be set during startup
        attr_accessor :auth_plugin
        attr_accessor :auth_cache_expiration
    end

	def current_uid 
        @current_uid ||= begin
            hdr = request.headers["Authorization"] 
            # NOTE - may run into key cache key size problems
            Rails.cache.fetch("uid/authHeader/#{hdr}", :expires_in => ApplicationController.auth_cache_expiration) do 
                ApplicationController.auth_plugin.uid_for_header(hdr)
            end
        end
    end

    def has_permission?(ctx, perm)
        return true
    end

    ### Misc
	def interpret_boolean(val)
		ActiveModel::Type::Boolean.new.cast(val)
	end
end
