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
		1.upto(10) do |val|
			metadata = {
				:number => val,
				:type => ((val % 2) == 0 ? "even" : "odd"),
				:size => ((val > 5) ? "big" : "small")
			}
			process(:post, "/v1/channels/metasearch/messages", :params => { :message => "Msg #{val}", :metadata => metadata })
		end
		process(:get, "/v1/channels/metasearch/messages/search", :params => { :metadata => { :number => 3 }})
		assert_response(:success)
		assert_equal(1, response.parsed_body.size)
		assert_equal(response.parsed_body[0]["message"], "Msg 3")

		process(:get, "/v1/channels/metasearch/messages/search", :params => { :metadata => { :type => :even, :size => :big }})
		assert_response(:success)
		assert_equal(3, response.parsed_body.size)
		assert_equal(response.parsed_body[0]["message"], "Msg 6")

		process(:get, "/v1/channels/metasearch/messages/search", :params => { :metadata => { :number => 3, :type => :even }})
		assert_response(:success)
		assert_equal(0, response.parsed_body.size)
	end

	test "Should do UID searches" do
		1.upto(5) do |val|
			process(:post, "/v1/channels/uidsearch/messages", :params => { :message => "Hello #{val}"}, :headers => { "Authorization" => auth_header_for_uid("user1") })
		end
		1.upto(7) do |val|
			process(:post, "/v1/channels/uidsearch/messages", :params => { :message => "Hello #{val}"}, :headers => { "Authorization" => auth_header_for_uid("user2") })
		end
		process(:get, "/v1/channels/uidsearch/messages/search", :params => { :publisher_uid => "user1"})
		assert_response(:success)
		assert_equal(5, response.parsed_body.size)
	end
end