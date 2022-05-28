# This can be used for custom auth validation
# A sidecar can be used to use localhost requests to get authentication
module Auth
    class Custom
        include HTTParty

        attr_accessor :endpoint

        def initialize(auth_endpoint)
            self.endpoint = auth_endpoint
        end

        def uid_for_token(tok)
            self.class.get(endpoint, :headers => {"Authorization" => "Bearer #{tok}"}).parsed_response["uid"]
        end
    end
end