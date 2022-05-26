require "test_helper"

class BasicFlowTest < ActionDispatch::IntegrationTest
	setup do
	end

	def run_basic_test(chname, should_autocomplete)
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
		get "#{subpath}/messages", :params => { :autocomplete => should_autocomplete }
		assert_response(:success)
		assert(response.parsed_body.size == 60)

		get "#{sub2path}/messages", :params => { :autocomplete => should_autocomplete }
		assert_response(:success)
		assert(response.parsed_body.size == 50)

		# Both subs should get all new messages
		loadqueue(chname, 10, "3")
		get "#{subpath}/messages", :params => { :autocomplete => should_autocomplete }
		assert(response.parsed_body.size == 10)
		get "#{sub2path}/messages", :params => { :autocomplete => should_autocomplete }
		assert(response.parsed_body.size == 10)

		# Both subs should now get zero messages
		get "#{subpath}/messages", :params => { :autocomplete => should_autocomplete }
		assert(response.parsed_body.size == 0)
		get "#{sub2path}/messages", :params => { :autocomplete => should_autocomplete }
		assert(response.parsed_body.size == 0)

		# Posting to a different channel, they should both still get zero messages
		loadqueue("#{chname}-alt", 10, "3")
		get "#{subpath}/messages", :params => { :autocomplete => should_autocomplete }
		assert(response.parsed_body.size == 0)
		get "#{sub2path}/messages", :params => { :autocomplete => should_autocomplete }
		assert(response.parsed_body.size == 0)
	end

	test "Basic Message Queue Ops" do
		# Should work if autocompleting
		chname = "BasicCh#{rand(1000)}"
		run_basic_test(chname, true)
		ch = Channel.where(:name => chname).first
		assert(ch.message_cursors.map{|x| x.active_readings.to_a}.flatten.count == 0)
		# Non-autocompleting should also work for this test
		ch2name = "Basic2Ch#{rand(1000)}"
		run_basic_test(ch2name, false)
		ch2 = Channel.where(:name => ch2name).first
		assert(ch2.message_cursors.map{|x| x.active_readings.to_a}.flatten.count == 130)
	end

	test "Basic draining queue test" do 
		chname = "DrainingCh#{rand(1000)}"

		# Configure queue to drain
		process(:put, "/v1/channels/#{chname}", :params => { :expire_messages => true })
		ch = Channel.where(:name => chname).first
		orig_count = ch.messages.count
		assert(orig_count == 0)

		# If the messages are completed, it should delete them
		run_basic_test(chname, true)
		Channel.clean_expired_messages!
		new_count = ch.messages.count 
		assert(new_count == orig_count)

		# If the messages aren't completed, it should keep them around
		run_basic_test(chname, false) # NOTE - will usually generate two new subscriptions
		Channel.clean_expired_messages!
		new_new_count = ch.messages.count 
		assert(new_new_count != new_count)

	end
end