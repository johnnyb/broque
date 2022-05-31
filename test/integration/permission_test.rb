class PermissionTest < ActionDispatch::IntegrationTest
	setup do
		@owner_uid = "TheOwner"
		@gpo_closed = FakeGlobalPermissionObject.new
		@gpo_closed.permission_required = true 
		@gpo_closed.authentication_required = true 
		@gpo_closed.owner_uid = @owner_uid 

		@gpo_authreq = FakeGlobalPermissionObject.new
		@gpo_authreq.permission_required = false 
		@gpo_authreq.authentication_required = true 
	end

	def basic_channel_perm_test(info)
		ch = "open#{rand(1000)}"

		desired_count = 0
		info.each do |uid, expect|
			process(:post, 
				"/v1/channels/#{ch}/messages", 
				:params => { :message => "hi" }, 
				:headers => { "Authorization" => auth_header_for_uid(uid) }
			)
			assert_response(expect)
			if expect == :success
				desired_count += 1
			end 
		end
		assert_equal(desired_count, Channel.where(:name => ch).first.messages.count)
	end

	test "Open Permissions" do
		Permission.global_permission_object = @gpo_open
		basic_channel_perm_test({
			"myuser" => :success, 
			"myuser2" => :success, 
			@owner_uid => :success,
			nil => :success
		})
	end

	test "Authreq GPO" do 
		Permission.global_permission_object = @gpo_authreq
		basic_channel_perm_test({
			"myuser" => :success,
			"myuser2" => :success,
			nil => 403,
			@owner_uid => :success
		})
	end

	test "Closed GPO" do
		Permission.global_permission_object = @gpo_closed
		basic_channel_perm_test({
			"myuser" => 403,
			"myuser2" => 403,
			nil => 403,
			@owner_uid => :success
		})
	end
end