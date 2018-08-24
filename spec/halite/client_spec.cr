require "../spec_helper"
require "../support/mock_server"

describe Halite::Client do
  describe "#initialize" do
    it "should initial with nothing" do
      client = Halite::Client.new
      client.should be_a(Halite::Client)
    end

    it "should initial with options" do
      client = Halite::Client.new(headers: {
        user_agent: "Spec",
      })

      client.should be_a(Halite::Client)
      client.options.headers["User-Agent"].should eq("Spec")
    end

    it "should initial with block" do
      client = Halite::Client.new do |options|
        options.headers = {
          private_token: "token",
        }
        options.read_timeout = 2.minutes
        options.timeout.connect = 40
      end

      client.should be_a(Halite::Client)
      client.options.headers.should be_a(HTTP::Headers)
      client.options.headers["Private-Token"].should eq("token")
      client.options.timeout.connect.should eq(40)
      client.options.timeout.read.should eq(120)
    end
  end

  describe "#sessions" do
    it "should store and send cookies" do
      # Start mock server
      server = MockServer.instance
      spawn do
        server.listen unless server.running?
      end

      # Wait server a moment
      sleep 1

      client = Halite::Client.new

      # get Set-Cookies from server
      r = client.get "#{server.endpoint}/cookies"
      r.headers["Set-Cookie"].should eq("foo=bar")

      r.cookies.size.should eq(1)
      r.cookies["foo"].value.should eq("bar")

      # request with stored cookies
      r = client.get "#{server.endpoint}/get-cookies"
      r.headers.has_key?("Set-Cookie").should be_false
      r.cookies.size.zero?.should be_true
      r.parse("json").as_h["foo"].should eq("bar")
    end
  end
end
