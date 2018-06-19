require "./spec_helper"
require "./support/mock_server"

# Start mock server
server = MockServer.new
spawn do
  server.listen
end

# Wait server a moment
sleep 1

describe Halite do
  it "returns a instance class" do
    client = Halite::Client.new
    client.should be_a(Halite::Client)
    client.options.should be_a(Halite::Options)
  end

  describe ".get" do
    context "loading a simple uri" do
      it "should easy to request" do
        response = Halite.get(server.endpoint)
        response.to_s.should match(/<!doctype html>/)
      end
    end

    context "with query string parameters" do
      it "should easy to request" do
        response = Halite.get("#{server.endpoint}/params", params: {foo: "bar"})
        response.to_s.should eq("Params!")
      end
    end

    context "with query string parameters in the URI and opts hash" do
      it "includes both" do
        response = Halite.get("#{server.endpoint}/multiple-params?foo=bar", params: {baz: "quux"})
        response.to_s.should eq("More Params!")
      end
    end

    context "with headers" do
      it "is easy" do
        response = Halite.accept("application/json").get(server.endpoint)
        response.to_s.should match(/json/)
      end
    end

    #   # context "loading binary data" do
    #   #   it "is encoded as bytes" do
    #   #     response = Halite.get "#{server.endpoint}/bytes"
    #   #     # response.to_s.encoding.should eq(Encoding::BINARY)
    #   #   end
    #   # end

    context "with a large request body" do
      [16_000, 16_500, 17_000, 34_000, 68_000].each do |size|
        [0, rand(0..100), rand(100..1000)].each do |fuzzer|
          context "with a #{size} body and #{fuzzer} of fuzzing" do
            it "returns a large body" do
              characters = ("A".."Z").to_a
              form = Hash(String, String).new.tap { |obj| (size + fuzzer).times { |i| obj[i.to_s] = characters[i % characters.size] } }
              response = Halite.post "#{server.endpoint}/echo-body", form: form
              response_body = HTTP::Params.escape(form)

              response.to_s.should eq(response_body)
              response.content_length.should eq(response_body.bytesize)
            end
          end
        end
      end
    end
  end

  describe ".post" do
    context "loading a simple form data" do
      it "should easy to request" do
        response = Halite.post("#{server.endpoint}/form", form: {example: "testing-form"})
        response.to_s.should eq("passed :)")
      end
    end
  end

  describe ".follow" do
    context "with redirects" do
      it "should easy for 301 with full uri" do
        response = Halite.follow.get("#{server.endpoint}/redirect-301")
        response.to_s.should match(/<!doctype html>/)
      end

      it "should easy for 301 with relative path" do
        response = Halite.follow.get("#{server.endpoint}/redirect-301", params: {"relative_path" => true})
        response.to_s.should match(/<!doctype html>/)
      end

      it "should easy for 301 with relative path which is not include slash" do
        response = Halite.follow.get("#{server.endpoint}/redirect-301", params: {"relative_path_without_slash" => true})
        response.to_s.should eq("hello")
      end

      it "should easy for 302" do
        response = Halite.follow.get("#{server.endpoint}/redirect-302")
        response.to_s.should match(/<!doctype html>/)
      end

      it "should store full history" do
        times = 5
        response = Halite.follow.get("#{server.endpoint}/multi-redirect?n=#{times}")
        response.history.class.should eq Array(Halite::Response)
        response.history.size.should eq(times + 1)
      end
    end
  end

  describe ".head" do
    it "should easy to request" do
      response = Halite.head server.endpoint
      response.status_code.should eq(200)
      response.content_type.should match(/html/)
    end
  end

  describe ".auth" do
    it "sets Authorization header to the given value" do
      client = Halite.auth("abc")
      client.options.headers["Authorization"].should eq("abc")
    end
  end

  describe ".basic_auth" do
    it "sets Authorization header with proper BasicAuth value" do
      client = Halite.basic_auth(user: "foo", pass: "bar")
      client.options.headers["Authorization"].should match(%r{^Basic [A-Za-z0-9+/]+=*$})
    end
  end

  describe ".timeout" do
    context "without timeout type" do
      it "sets given timeout options" do
        client = Halite.timeout(connect: 12, read: 6)
        client.options.timeout.read.should eq(6)
        client.options.timeout.connect.should eq(12)
      end
    end
  end

  describe ".cookies" do
    it "passes correct `Cookie` header" do
      client = Halite.cookies(abc: "def").get("#{server.endpoint}/cookies")
      client.to_s.should eq("abc: def")
    end

    it "properly works with cookie jars from response" do
      res = Halite.get("#{server.endpoint}/cookies")
      client = Halite.cookies(res.cookies).get("#{server.endpoint}/cookies")
      client.to_s.should eq("foo: bar")
    end

    it "properly merges cookies" do
      res = Halite.get("#{server.endpoint}/cookies")
      client = Halite.cookies(foo: 123, bar: 321).cookies(res.cookies)
      client.get("#{server.endpoint}/cookies").to_s.should eq("foo: bar\nbar: 321")
    end
  end

  it "should throws a Halite::ConnectionError exception with not exist uri" do
    expect_raises Halite::ConnectionError do
      Halite.get("http://404-not_found.xyz/")
    end
  end

  it "should throws a Halite::ConnectionError exception with illegal port" do
    expect_raises Halite::ConnectionError do
      Halite.get("http://127.0.0.1:000")
    end
  end

  it "should throws a Halite::TimeoutError exception with long time not response" do
    expect_raises Halite::TimeoutError do
      Halite.timeout(1.milliseconds).get("http://404notfound.xyz")
    end
  end

  it "should throws a Halite::RequestError exception with http request via ssl" do
    expect_raises Halite::RequestError, "SSL context given for HTTP URI = http://google.com" do
      Halite.get("http://google.com", ssl: OpenSSL::SSL::Context::Client.new)
    end
  end
end

# Clean up
server.close
