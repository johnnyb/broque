class Kubernetes::Client
    def self.shared
        @client ||= get_new_client
        return @client
    end

    def self.current_namespace
        @ns ||= File.open("/var/run/secrets/kubernetes.io/serviceaccount/namespace").read
        return @ns
    end

    def self.get_new_client
        auth_options = {
            bearer_token_file: '/var/run/secrets/kubernetes.io/serviceaccount/token'
        }
        ssl_options = {}
        if File.exist?("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
            ssl_options[:ca_file] = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
        end
        client = Kubeclient::Client.new(
            'https://kubernetes.default.svc',
            'v1',
            auth_options: auth_options,
            ssl_options:  ssl_options
        )
        return client
    end
end