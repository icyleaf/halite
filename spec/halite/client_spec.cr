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
      client = Halite::Client.new do
        headers(private_token: "token")
        timeout(read: 2.minutes, connect: 40)
      end

      client.should be_a(Halite::Client)
      client.options.headers.should be_a(HTTP::Headers)
      client.options.headers["Private-Token"].should eq("token")
      client.options.timeout.connect.should eq(40)
      client.options.timeout.read.should eq(120)
    end

    it "should initial with empty block" do
      client = Halite::Client.new { }
      client.should be_a(Halite::Client)
    end
  end

  describe "#request" do
    %w[get post put delete head patch options].each do |verb|
      it "should easy to #{verb} request" do
        response = Halite::Client.new.request(verb, SERVER.endpoint)
        response.status_code.should eq(200)
      end
      it "should easy to #{verb} request with hash or namedtuple" do
        response = Halite::Client.new.request(verb, SERVER.endpoint, params: {name: "foo"})
        response.status_code.should eq(200)
      end

      it "should easy to #{verb} request with options" do
        response = Halite::Client.new.request(verb, SERVER.endpoint)
        response.status_code.should eq(200)
      end

      it "should easy to #{verb} streaming request" do
        data = [] of JSON::Any
        Halite::Client.new.request(verb, SERVER.api("stream?n=2")) do |response|
          response.status_code.should eq 200
          response.headers["Transfer-Encoding"].should eq "chunked"

          if verb != "head"
            while content = response.body_io.gets
              data << JSON.parse(content)
            end
          else
            expect_raises Exception, "Nil assertion failed" do
              response.body_io
            end
          end
        end

        if verb != "head"
          data.size.should eq 2
          data.first.as_h["verb"].should eq verb.upcase
        else
          data.size.should eq 0
        end
      end
    end
  end

  # It accepts all chainable methods, see halite_spec.cr

  describe "#sessions" do
    it "should store and send cookies" do
      client = Halite::Client.new

      # get Set-Cookies from server
      r = client.get SERVER.api("cookies")
      r.headers["Set-Cookie"].should eq("foo=bar")

      r.cookies.size.should eq(1)
      r.cookies["foo"].value.should eq("bar")

      # request with stored cookies
      r = client.get SERVER.api("get-cookies")
      r.headers.has_key?("Set-Cookie").should be_false
      r.cookies.size.zero?.should be_true
      r.parse("json").as_h["foo"].should eq("bar")
    end
  end
end
