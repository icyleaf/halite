require "./spec_helper"

describe Halite do
  describe ".new" do
    it "returns a instance class" do
      client = Halite::Client.new
      client.should be_a(Halite::Client)
      client.options.should be_a(Halite::Options)
    end
  end

  describe ".get" do
    context "loading a simple uri" do
      it "should easy to request" do
        response = Halite.get(SERVER.endpoint)
        response.to_s.should match(/<!doctype html>/)
      end
    end

    context "with query string parameters" do
      it "should easy to request" do
        response = Halite.get(SERVER.api("params"), params: {foo: "bar"})
        response.to_s.should eq("Params!")
      end
    end

    context "with query string parameters in the URI and opts hash" do
      it "includes both" do
        response = Halite.get("#{SERVER.endpoint}/multiple-params?foo=bar", params: {baz: "quux"})
        response.to_s.should eq("More Params!")
      end
    end

    context "streaming" do
      it "is easy" do
        data = [] of JSON::Any
        Halite.headers("via": "foo").get(SERVER.api("stream?n=2")) do |response|
          response.status_code.should eq 200
          response.headers["Transfer-Encoding"].should eq "chunked"
          while content = response.body_io.gets
            data << JSON.parse(content)
          end
        end

        data.size.should eq 2
        data.first.as_h["verb"].should eq "GET"
        data.first.as_h["headers"].as_h["Via"].should eq "foo"
      end
    end

    context "with headers" do
      it "is easy" do
        response = Halite.accept("application/json").get(SERVER.endpoint)
        response.to_s.should match(/json/)
      end
    end

    context "loading binary data" do
      it "is a png file" do
        response = Halite.get SERVER.api("image")
        response.headers["Content-Type"].should eq "image/png"
        response.filename.should eq "logo.png"
      end

      it "with streaming" do
        original_path = File.expand_path("../../halite-logo.png", __FILE__)
        Halite.get SERVER.api("image") do |response|
          File.open(original_path, "r") do |original_file|
            while byte = response.body_io.read_byte
              original_file.read_byte.should eq byte
            end
          end
        end
      end
    end

    context "with a large request body" do
      [16_000, 16_500, 17_000, 34_000, 68_000].each do |size|
        [0, rand(0..100), rand(100..1000)].each do |fuzzer|
          context "with a #{size} body and #{fuzzer} of fuzzing" do
            it "returns a large body" do
              characters = ("A".."Z").to_a
              form = Hash(String, String).new.tap { |obj| (size + fuzzer).times { |i| obj[i.to_s] = characters[i % characters.size] } }
              response = Halite.post SERVER.api("echo-body"), form: form
              response_body = HTTP::Params.encode(form)

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
      it "should easy to request with form data" do
        response = Halite.post(SERVER.api("form"), form: {example: "testing-form"})
        response.to_s.should contain("example: testing-form")
      end

      it "should easy to request with raw string" do
        response = Halite.post(SERVER.api("form"), raw: "example=testing-form")
        response.to_s.should contain("example: testing-form")
      end

      it "should easy to request with json data" do
        response = Halite.post(SERVER.api("form"), json: {"job" => {"title" => ["foo", "bar"], "info" => {gender: "male"}}})
        response.to_s.should contain(%Q({"job":{"title":["foo","bar"],"info":{"gender":"male"}}}))
      end
    end

    context "uploading file" do
      it "should easy upload only file" do
        response = Halite.post(SERVER.api("upload"), form: {file: File.open("./src/halite.cr")})
        body = response.parse.as_h
        params = body["params"].as_h
        files = body["files"].as_h

        params.size.should eq 0

        files.size.should eq 1
        files["file"]?.should be_a JSON::Any
        files["file"].as_h["filename"].should eq "halite.cr"
      end

      it "should easy upload file with other form data" do
        response = Halite.post(SERVER.api("upload"), form: {file: File.open("./src/halite.cr"), "name": "foobar"})
        body = response.parse.as_h
        params = body["params"].as_h
        files = body["files"].as_h

        params.size.should eq 1
        params["name"].should eq "foobar"

        files.size.should eq 1
        files["file"]?.should be_a JSON::Any
        files["file"].as_h["filename"].should eq "halite.cr"
      end

      it "should easy upload multiple files" do
        response = Halite.post(SERVER.api("upload"), form: {avatar: [File.open("halite-logo.png"), File.open("halite-logo-small.png")]})
        body = response.parse.as_h
        params = body["params"].as_h
        files = body["files"].as_h

        params.size.should eq 0
        files.size.should eq 1
        files["avatar"]?.should be_a JSON::Any
        files["avatar"].as_a.size.should eq 2
        files["avatar"].as_a[0].as_h["filename"].should eq "halite-logo.png"
        files["avatar"].as_a[1].as_h["filename"].should eq "halite-logo-small.png"
      end

      it "should easy upload multiple files with other form data" do
        response = Halite.post(SERVER.api("upload"), form: {
          avatar: [File.open("halite-logo.png"), File.open("halite-logo-small.png")],
          name:   "foobar",
        })
        body = response.parse.as_h
        params = body["params"].as_h
        files = body["files"].as_h

        params.size.should eq 1
        params["name"].should eq "foobar"

        files.size.should eq 1
        files["avatar"]?.should be_a JSON::Any
        files["avatar"].as_a.size.should eq 2
        files["avatar"].as_a[0].as_h["filename"].should eq "halite-logo.png"
        files["avatar"].as_a[1].as_h["filename"].should eq "halite-logo-small.png"
      end
    end

    context "streaming" do
      it "is easy" do
        data = [] of JSON::Any
        Halite.post(SERVER.api("stream?n=2")) do |response|
          response.status_code.should eq 200
          response.headers["Transfer-Encoding"].should eq "chunked"
          while content = response.body_io.gets
            data << JSON.parse(content)
          end
        end

        data.size.should eq 2
        data.first.as_h["verb"].should eq "POST"
      end
    end
  end

  describe ".put" do
    it "should easy to request" do
      response = Halite.put SERVER.endpoint
      response.status_code.should eq(200)
      response.content_type.should match(/html/)
    end

    context "streaming" do
      it "is easy" do
        data = [] of JSON::Any
        Halite.put(SERVER.api("stream?n=2")) do |response|
          response.status_code.should eq 200
          response.headers["Transfer-Encoding"].should eq "chunked"
          while content = response.body_io.gets
            data << JSON.parse(content)
          end
        end

        data.size.should eq 2
        data.first.as_h["verb"].should eq "PUT"
      end
    end
  end

  describe ".delete" do
    it "should easy to request" do
      response = Halite.delete SERVER.endpoint
      response.status_code.should eq(200)
      response.content_type.should match(/html/)
    end

    context "streaming" do
      it "is easy" do
        data = [] of JSON::Any
        Halite.delete(SERVER.api("stream?n=2")) do |response|
          response.status_code.should eq 200
          response.headers["Transfer-Encoding"].should eq "chunked"
          while content = response.body_io.gets
            data << JSON.parse(content)
          end
        end

        data.size.should eq 2
        data.first.as_h["verb"].should eq "DELETE"
      end
    end
  end

  describe ".patch" do
    it "should easy to request" do
      response = Halite.patch SERVER.endpoint
      response.status_code.should eq(200)
      response.content_type.should match(/html/)
    end

    context "streaming" do
      it "is easy" do
        data = [] of JSON::Any
        Halite.patch(SERVER.api("stream?n=2")) do |response|
          response.status_code.should eq 200
          response.headers["Transfer-Encoding"].should eq "chunked"
          while content = response.body_io.gets
            data << JSON.parse(content)
          end
        end

        data.size.should eq 2
        data.first.as_h["verb"].should eq "PATCH"
      end
    end
  end

  describe ".head" do
    it "should easy to request" do
      response = Halite.head SERVER.endpoint
      response.status_code.should eq(200)
      response.content_type.should match(/html/)
    end
  end

  describe ".options" do
    it "should easy to request" do
      response = Halite.options SERVER.endpoint
      response.status_code.should eq(200)
      response.content_type.should match(/html/)
    end

    context "streaming" do
      it "is easy" do
        data = [] of JSON::Any
        Halite.options(SERVER.api("stream?n=2")) do |response|
          response.status_code.should eq 200
          response.headers["Transfer-Encoding"].should eq "chunked"
          while content = response.body_io.gets
            data << JSON.parse(content)
          end
        end

        data.size.should eq 2
        data.first.as_h["verb"].should eq "OPTIONS"
      end
    end
  end

  describe ".request" do
    %w[get post put delete head patch options].each do |verb|
      it "should easy to #{verb} request" do
        response = Halite.request(verb, SERVER.endpoint)
        response.status_code.should eq(200)
      end

      it "should easy to #{verb} request with hash or namedtuple" do
        response = Halite.request(verb, SERVER.endpoint, params: {name: "foo"})
        response.status_code.should eq(200)
      end

      it "should easy to #{verb} request with options" do
        response = Halite.request(verb, SERVER.endpoint, Halite::Options.new)
        response.status_code.should eq(200)
      end

      it "should easy to #{verb} streaming request" do
        data = [] of JSON::Any
        Halite.request(verb, SERVER.api("stream?n=2")) do |response|
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

    it "throws an exception with non-support method" do
      expect_raises Halite::UnsupportedMethodError do
        Halite.request("abc", SERVER.endpoint)
      end
    end

    it "throws an exception with non-support scheme" do
      expect_raises Halite::UnsupportedSchemeError do
        Halite.request("get", "ws://example.com/abc")
      end
    end

    it "throws an exception without scheme" do
      expect_raises Halite::UnsupportedSchemeError do
        Halite.request("get", "example.com/abc")
      end
    end
  end

  describe ".follow" do
    context "without redirects" do
      it "should return empty history" do
        response = Halite.get(SERVER.api("/"))
        response.history.size.should eq(0)
      end
    end

    context "with redirects" do
      it "should return one history with non-redirect url" do
        response = Halite.follow.get(SERVER.api("/"))
        response.history.size.should eq(1)
        response.to_s.should match(/<!doctype html>/)
      end

      it "should easy for 301 with full uri" do
        response = Halite.follow.get(SERVER.api("redirect-301"))
        response.history.size.should eq(2)
        response.to_s.should match(/<!doctype html>/)
      end

      it "should easy for 301 with relative path" do
        response = Halite.follow.get(SERVER.api("redirect-301"), params: {"relative_path" => true})
        response.history.size.should eq(2)
        response.to_s.should match(/<!doctype html>/)
      end

      it "should easy for 301 with relative path which is not include slash" do
        response = Halite.follow.get(SERVER.api("redirect-301"), params: {"relative_path_without_slash" => true})
        response.history.size.should eq(2)
        response.to_s.should eq("hello")
      end

      it "should easy for 302" do
        response = Halite.follow.get(SERVER.api("redirect-302"))
        response.history.size.should eq(2)
        response.to_s.should match(/<!doctype html>/)
      end

      it "should store full history" do
        times = 5
        response = Halite.follow.get("#{SERVER.endpoint}/multi-redirect?n=#{times}")
        response.history.class.should eq Array(Halite::Response)
        response.history.size.should eq(times + 1)
      end
    end
  end

  describe ".endpoint" do
    it "sets endpoint with String" do
      endpoint = "https://example.com"
      client = Halite.endpoint(endpoint)
      client.options.endpoint.should eq(URI.parse(endpoint))
    end

    it "sets endpoint with String" do
      endpoint = URI.parse("https://example.com")
      client = Halite.endpoint(endpoint)
      client.options.endpoint.should eq(endpoint)
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

  describe ".user_agent" do
    it "uses default user agent" do
      r = Halite.get SERVER.api("user_agent")
      r.body.should eq(Halite::Request::USER_AGENT)
    end

    it "sets user agent" do
      user_agent = "Awesome Halite Client"
      client = Halite.user_agent(user_agent)
      client.options.headers["User-Agent"].should eq(user_agent)

      r = client.get SERVER.api("user_agent")
      r.body.should eq(user_agent)
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
      response = Halite.cookies(abc: "def").get(SERVER.api("cookies"))
      response.to_s.should eq("abc: def")
    end

    it "properly works with cookie jars from response" do
      cookies = Halite.get(SERVER.api("cookies")).cookies
      response = Halite.cookies(cookies).get(SERVER.api("cookies"))
      response.to_s.should eq("foo: bar")
    end

    it "properly merges cookies" do
      cookies = Halite.get(SERVER.api("cookies")).cookies
      response = Halite.cookies(foo: 123, bar: 321).cookies(cookies).get(SERVER.api("cookies"))
      response.to_s.should contain("foo: bar\nbar: 321")
    end
  end

  describe ".logging" do
    it "should use logging" do
      client = Halite.logging
      client.options.features.has_key?("logging").should be_true
      client.options.features["logging"].should be_a(Halite::Logging)
      logging = client.options.features["logging"].as(Halite::Logging)
      logging.writer.should be_a(Halite::Logging::Common)
      logging.writer.skip_request_body.should be_false
      logging.writer.skip_response_body.should be_false
      logging.writer.skip_benchmark.should be_false
      logging.writer.colorize.should be_true
    end

    it "sets logging with format" do
      client = Halite.logging(format: "json", skip_response_body: true)
      client.options.features.has_key?("logging").should be_true
      client.options.features["logging"].should be_a(Halite::Logging)
      logging = client.options.features["logging"].as(Halite::Logging)
      logging.writer.should be_a(Halite::Logging::JSON)
      logging.writer.skip_request_body.should be_false
      logging.writer.skip_response_body.should be_true
      logging.writer.skip_benchmark.should be_false
      logging.writer.colorize.should be_true
    end

    it "sets logging into file" do
      with_tempfile("halite-spec-logging") do |file|
        client = Halite.logging(file: file, skip_response_body: true)
        client.options.features.has_key?("logging").should be_true
        client.options.features["logging"].should be_a(Halite::Logging)
        logging = client.options.features["logging"].as(Halite::Logging)
        logging.writer.should be_a(Halite::Logging::Common)
        logging.writer.skip_request_body.should be_false
        logging.writer.skip_response_body.should be_true
        logging.writer.skip_benchmark.should be_false
        logging.writer.colorize.should be_true

        client.get SERVER.endpoint
        logs = File.read_lines(file).join("\n")
        logs.should contain("request")
        logs.should contain("response")
        logs.should_not contain("<!doctype html><body>Mock Server is running.</body></html>")
      end
    end

    it "sets logging with custom logging" do
      client = Halite.logging(logging: SimpleLogger.new(skip_benchmark: true))
      client.options.features.has_key?("logging").should be_true
      client.options.features["logging"].should be_a(Halite::Logging)
      logging = client.options.features["logging"].as(Halite::Logging)
      logging.writer.should be_a(SimpleLogger)
      logging.writer.skip_request_body.should be_false
      logging.writer.skip_response_body.should be_false
      logging.writer.skip_benchmark.should be_true
      logging.writer.colorize.should be_true
    end
  end

  describe ".use" do
    describe "built-in features" do
      it "sets given feature name" do
        client = Halite.use("logging")
        client.options.features.has_key?("logging").should be_true
        client.options.features["logging"].should be_a(Halite::Logging)
        logging = client.options.features["logging"].as(Halite::Logging)
        logging.writer.should be_a(Halite::Logging::Common)
        logging.writer.skip_request_body.should be_false
        logging.writer.skip_response_body.should be_false
        logging.writer.skip_benchmark.should be_false
        logging.writer.colorize.should be_true
      end

      it "sets logging with logging" do
        client = Halite.use("logging", logging: Halite::Logging::JSON.new(skip_request_body: true, colorize: false))
        client.options.features.has_key?("logging").should be_true
        client.options.features["logging"].should be_a(Halite::Logging)
        logging = client.options.features["logging"].as(Halite::Logging)
        logging.writer.should be_a(Halite::Logging::JSON)
        logging.writer.skip_request_body.should be_true
        logging.writer.skip_response_body.should be_false
        logging.writer.skip_benchmark.should be_false
        logging.writer.colorize.should be_false

        # Restore
        Colorize.on_tty_only!
      end
    end

    describe "custom features" do
      it "should modify the headers of request and response" do
        response = Halite.use("append_headers").get(SERVER.api("/anything?a=b"))
        response.headers["X-Powered-By"].should eq("Halite")
        response.parse.as_h["headers"]["X-API-Limit"].should eq("60")
      end

      it "should mock response with interceptor" do
        response = Halite.use("mock").get(SERVER.api("/anything?a=b"))
        response.status_code.should eq(400)
        response.body.should eq("mock")
      end

      describe "enable multiple interceptors" do
        it "should call next intercept" do
          response = Halite.use("404").use("powered_by").get(SERVER.api("/anything?a=b"))
          response.status_code.should eq(404)
          response.headers["X-Powered-By"].should eq("Halite")
          response.body.should_not eq("")
        end

        it "should return on first interceptor" do
          response = Halite.use("mock").use("404").get(SERVER.api("/anything?a=b"))
          response.status_code.should eq(400)
          response.body.should eq("mock")
        end
      end
    end
  end

  describe "raise" do
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
        Halite.timeout(connect: 1.milliseconds).get("http://404notfound.xyz")
      end
    end

    it "should throws a Halite::RequestError exception with http request via tls" do
      expect_raises Halite::RequestError, "SSL context given for HTTP URI = http://google.com" do
        Halite.timeout(connect: 1.milliseconds).get("http://google.com", tls: OpenSSL::SSL::Context::Client.new)
      end
    end
  end

  describe Halite::FeatureRegister do
    it "should use a registered feature" do
      Halite.feature?("null").should be_nil
      Halite.register_feature "null", TestFeatures::Null
      Halite.has_feature?("null").should be_true
      Halite.feature("null").should eq(TestFeatures::Null)
    end
  end
end
