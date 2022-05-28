class Kubernetes::Client
    include HTTParty
    ssl_ca_file "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

    attr_accessor :base_url
    attr_accessor :namespace
    attr_accessor :token 

    def initialize(opts = {})
        self.base_url = opts[:base_url] || "https://kubernetes.default.svc"
        self.namespace = opts[:namespace] || File.open("/var/run/secrets/kubernetes.io/serviceaccount/namespace").read
        self.token = opts[:token] || File.open("/var/run/secrets/kubernetes.io/serviceaccount/token").read
    end

    def self.shared
        @client ||= Kubernetes::Client.new
        return @client
    end

    def api_get(path)
    end

    def api_post(path, body)
        self.class.post("#{base_url}#{path}", :headers => {
            "Authorization" => "Bearer #{token}",
            "Content-Type" => "application/json"
        })
    end 
end