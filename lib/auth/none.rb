module Auth
	class None 
		def uid_for_header(tok)
			nil
		end
	end
end