class Kubernetes::Client
    include HTTParty
    ssl_ca_file "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

    attr_accessor :base_url
    attr_accessor :namespace
    attr_accessor :token
    attr_accessor :token_path

    def initialize(opts = {})
        self.base_url = opts[:base_url] || "https://kubernetes.default.svc"
        self.namespace = opts[:namespace] || begin
            File.open("/var/run/secrets/kubernetes.io/serviceaccount/namespace").read
        rescue
            "default"
        end
        self.token_path = opts[:token_path] || "/var/run/secrets/kubernetes.io/serviceaccount/token"
        self.token = opts[:token]
    end

    def self.shared
        @client ||= Kubernetes::Client.new
        return @client
    end

    def api_get(path)
    end

    def my_token
        return token if token.present? # If a specific token is specified, use that

        # Periodically refresh token from the path in case they are cycling tokens
        Rails.cache.fetch("auth/mytoken", :expires_in => 1.hour) do
            File.open(token_path).read
        end
    end

    def api_get(path)
        self.class.get("#{base_url}#{path}", :headers => {
            "Authorization" => "Bearer #{my_token}"
        })
    end

    def api_post(path, body)
        self.class.post("#{base_url}#{path}", :headers => {
            "Authorization" => "Bearer #{my_token}",
            "Content-Type" => "application/json"
        })
    end 
end