require "test_helper"

class SearchTest < ActionDispatch::IntegrationTest
	setup do
	end

	test "Test limit/offset" do
		loadqueue("limitchan", 200, "SearchMsg")
		process(:get, "/v1/channels/limitchan/messages/search", :params => { :max_messages => 9 })
		assert_response(:success)
		assert_equal(response.parsed_body.size, 9)
		assert_equal(response.parsed_body.first["message"], "SearchMsg 1")
		assert_equal(response.parsed_body.last["message"], "SearchMsg 9")

		process(:get, "/v1/channels/limitchan/messages/search", :params => { :max_messages => 9, :offset => 7 })
		assert_response(:success)
		assert_equal(response.parsed_body.size, 9)
		assert_equal("SearchMsg 8", response.parsed_body.first["message"])
		assert_equal("SearchMsg 16", response.parsed_body.last["message"])
	end

	test "Should do metadata searches" do 
	end

	test "Should do UID searches" do
		1.upto(5) do |val|
			process(:post, "/v1/channels/uidsearch/messages", :params => { :message => "Hello #{val}"}, :headers => { "Authorization" => "user1" })
		end
		1.upto(7) do |val|
			process(:post, "/v1/channels/uidsearch/messages", :params => { :message => "Hello #{val}"}, :headers => { "Authorization" => "user2" })
		end
		process(:get, "/v1/channels/uidsearch/messages/search", :params => { :publisher_uid => "user1"})
		assert_response(:success)
		assert_equal(response.parsed_body.size, 5)
	end
end