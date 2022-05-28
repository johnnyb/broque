module Auth
    class Kubernetes
        def user_user_data_for_token(tok)
            results = Kubernetes::Client.api_post("/apis/authentication.k8s.io/v1/tokenreviews", {
                :apiVersion => "authentication.k8s.io/v1",
                :kind => "TokenReview",
                :spec => {
                    :token => tok
                }
            }).parsed_response

            return results["status"]["user"]
        end

        def uid_for_token(tok)
            user_data_for_token(tok)["username"]
        end
    end
end