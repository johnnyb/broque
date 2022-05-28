module Auth
    class None 
        def uid_for_token(tok)
            nil
        end
    end
end