class ApplicationController < ActionController::API
    def current_uid 
        "none"
    end

    def has_permission?(name)
        return true
    end
end
