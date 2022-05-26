require "test_helper"

class BasicFlowTest < ActionDispatch::IntegrationTest
	setup do
	end

	test "Basic Message Queue Ops" do
		chname = "Ch#{rand(1000)}"
		chpath = "/v1/channels/#{chname}"
		msgpath = "#{chpath}/messages"
		subname = "Sub#{rand(1000)}"
		subpath = "#{chpath}/subscriptions/#{subname}"

		process(:put, subpath)
		assert_response(:success)
		subdata = response.parsed_body 

		# Load up the queue
		loadqueue(chname, 10, "1")

		# 2nd subscription should not get those first 10
		sub2name = "#{subname}-foo"
		sub2path = "#{chpath}/subscriptions/#{sub2name}"
		process(:put, sub2path) 
		assert_response(:success)
		
		# Load up the queue some more
		loadqueue(chname, 50, "2")

		# Each sub should get a different number of responses
		get "#{subpath}/messages"
		assert_response(:success)
		assert(response.parsed_body.size == 60)

		get "#{sub2path}/messages"
		assert_response(:success)
		assert(response.parsed_body.size == 50)

		# Both subs should get all new messages
		loadqueue(chname, 10, "3")
		get "#{subpath}/messages"
		assert(response.parsed_body.size == 10)
		get "#{sub2path}/messages"
		assert(response.parsed_body.size == 10)

		# Both subs should now get zero messages
		get "#{subpath}/messages"
		assert(response.parsed_body.size == 0)
		get "#{sub2path}/messages"
		assert(response.parsed_body.size == 0)

		# Posting to a different channel, they should both still get zero messages
		loadqueue("#{chname}-alt", 10, "3")
		get "#{subpath}/messages"
		assert(response.parsed_body.size == 0)
		get "#{sub2path}/messages"
		assert(response.parsed_body.size == 0)
	end
end