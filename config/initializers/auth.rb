# Configuration authorization
require "auth/none"
require "auth/kubernetes"
require "auth/custom"
require "application_controller"

auth_plugin = Auth::None.new
case ENV["AUTH_METHOD"].to_s.downcase
    when  "kubernetes"
            auth_plugin = Auth::Kubernetes.new
    when "custom"
            auth_plugin = Auth::Custom.new(ENV["AUTH_CUSTOM_ENDPOINT"])
end
ApplicationController.auth_plugin = auth_plugin
ApplicationController.token_caching_time = (ENV["AUTH_TOKEN_CACHE_EXPIRATION"] || 900).to_i.seconds