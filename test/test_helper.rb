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

	def auth_header_for_uid(uid)
		return uid
	end

	setup do
		# Auth is done by simply sending the UID as the auth header
		ApplicationController.auth_plugin = FakeAuth.new

		# Setup open permissions explicitly so it gets reset after other permission tests
		@gpo_open = FakeGlobalPermissionObject.new
		@gpo_open.owner_uid = nil 
		@gpo_open.authentication_required = false 
		@gpo_open.permission_required = false 
		Permission.global_permission_object = @gpo_open
	end
end

class FakeAuth
	def uid_for_header(hdr)
		return hdr
	end
end

class FakeGlobalPermissionObject
	attr_accessor :authentication_required
	attr_accessor :permission_required
	attr_accessor :owner_uid

	def authentication_required?
		authentication_required
	end

	def permission_required?
		permission_required
	end

	def install!
		Permission.global_permission_object = self
	end
end