ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
	# Run tests in parallel with specified workers
	parallelize(workers: :number_of_processors)

	# Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
	fixtures :all

	# Add more helper methods to be used by all tests here...

	def loadqueue(name, num_messages, tag="", opts = {})
		1.upto(num_messages) do |idx|
			process(:post, "/v1/channels/#{name}/messages", :params => {:message => "#{tag} #{idx}"})
		end
	end

	def get(path, opts = {})
		process(:get, path, opts)
	end

	setup do
		ApplicationController.auth_plugin = FakeAuth.new
	end
end

class FakeAuth
	def uid_for_header(hdr)
		return hdr
	end
end
