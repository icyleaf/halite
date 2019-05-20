require "../spec_helper"

private class SimpleFeature < Halite::Feature
  def request(request)
    request
  end

  def response(response)
    response
  end

  Halite.register_feature "simple", self
end

private class SimpleLogger < Halite::Logging::Abstract
  def request(request)
    @logger.info "request"
  end

  def response(response)
    @logger.info "response"
  end

  Halite::Logging.register "simple", self
end

private def test_options
  Halite::Options.new(
    endpoint: "https://spec.example.com",
    headers: {
      user_agent: "spec",
    },
    params: {"title" => "h1"},
    form: {"title" => "h2"},
    json: {"title" => "h3"},
    raw: "title=h4",
    connect_timeout: 1,
    read_timeout: 3.2,
    follow: 2,
    follow_strict: false,
    tls: OpenSSL::SSL::Context::Client.new,
    features: {
      "logging" => Halite::Logging.new.as(Halite::Feature),
    }
  )
end

describe Halite::Options do
  describe "#initialize" do
    it "should initial with nothing" do
      options = Halite::Options.new
      options.should be_a(Halite::Options)

      options.endpoint.should be_nil

      options.headers.empty?.should be_true

      options.cookies.should be_a(HTTP::Cookies)
      options.cookies.size.should eq(0)

      options.timeout.should be_a(Halite::Timeout)
      options.timeout.connect.should be_nil
      options.timeout.read.should be_nil
      options.connect_timeout.should be_nil
      options.read_timeout.should be_nil

      options.follow.should be_a(Halite::Follow)
      options.follow.hops.should eq(Halite::Follow::DEFAULT_HOPS)
      options.follow.strict.should eq(Halite::Follow::STRICT)
      options.follow_strict.should eq(Halite::Follow::STRICT)

      options.tls.should be_nil
      options.params.should eq({} of String => Halite::Options::Type)
      options.form.should eq({} of String => Halite::Options::Type)
      options.json.should eq({} of String => Halite::Options::Type)
      options.raw.should be_nil
    end

    it "should initial with original" do
      options = Halite::Options.new(headers: {
        "private_token" => "token",
      },
        timeout: Halite::Timeout.new(connect: 3.2),
        endpoint: "https://example.com"
      )

      options.should be_a(Halite::Options)
      options.endpoint.should eq(URI.parse("https://example.com"))
      options.headers.should be_a(HTTP::Headers)
      options.headers["Private-Token"].should eq("token")
      options.timeout.connect.should eq(3.2)
    end

    it "should initial with quick setup" do
      endpoint = URI.parse("https://example.com")
      options = Halite::Options.new(headers: {
        private_token: "token",
      },
        connect_timeout: 1.minutes,
        endpoint: endpoint
      )

      options.should be_a(Halite::Options)
      options.endpoint.should eq(endpoint)
      options.headers.should be_a(HTTP::Headers)
      options.headers["Private-Token"].should eq("token")
      options.timeout.connect.should eq(60)
    end

    it "should overwrite default headers" do
      options = Halite::Options.new(
        headers: {
          user_agent: "spec",
        },
      )

      options.should be_a(Halite::Options)
      options.headers["User-Agent"].should eq("spec")
    end
  end

  describe "#merge!" do
    it "should works with Halite::Options" do
      old_options = test_options
      endpoint = old_options.endpoint
      new_tls = OpenSSL::SSL::Context::Client.new
      options = old_options.merge!(Halite::Options.new(
        headers: {
          user_agent: "new_spec",
        },
        params: {"title" => "1"},
        form: {"title" => "2"},
        json: {"title" => "3"},
        raw: "title=4",
        connect_timeout: 2,
        follow: 1,
        tls: new_tls,
        features: {
          "cache" => Halite::Cache.new.as(Halite::Feature),
        }
      ))

      old_options.endpoint.should eq(endpoint)
      old_options.headers.should eq(HTTP::Headers{"User-Agent" => "new_spec"})
      old_options.cookies.size.should eq(0)
      old_options.timeout.connect.should eq(2)
      old_options.timeout.read.should be_nil
      old_options.connect_timeout.should eq(2)
      old_options.read_timeout.should be_nil
      old_options.follow.hops.should eq(1)
      old_options.follow.strict.should be_true
      old_options.params.should eq({"title" => "1"})
      old_options.form.should eq({"title" => "2"})
      old_options.json.should eq({"title" => "3"})
      old_options.raw.should_not be_nil
      old_options.raw.not_nil!.should eq("title=4")
      old_options.tls.not_nil!.should eq(new_tls)
      options.features["logging"].should be_a(Halite::Logging)
      options.features["cache"].should be_a(Halite::Cache)

      options.endpoint.should eq(endpoint)
      options.headers.should eq(HTTP::Headers{"User-Agent" => "new_spec"})
      options.cookies.size.should eq(0)
      options.timeout.connect.should eq(2)
      options.timeout.read.should be_nil
      options.connect_timeout.should eq(2)
      options.read_timeout.should be_nil
      options.follow.hops.should eq(1)
      options.follow.strict.should be_true
      options.params.should eq({"title" => "1"})
      options.form.should eq({"title" => "2"})
      options.json.should eq({"title" => "3"})
      options.raw.should_not be_nil
      options.raw.not_nil!.should eq("title=4")
      options.tls.not_nil!.should eq(new_tls)
      options.features["logging"].should be_a(Halite::Logging)
      options.features["cache"].should be_a(Halite::Cache)
    end
  end

  describe "#merge" do
    it "should works with Halite::Options" do
      old_options = test_options
      endpoint = old_options.endpoint
      new_tls = OpenSSL::SSL::Context::Client.new
      options = old_options.merge(Halite::Options.new(
        endpoint: "https://new.exaple.com",
        headers: {
          user_agent: "new_spec",
        },
        params: {"title" => "1"},
        form: {"title" => "2"},
        json: {"title" => "3"},
        raw: "title=4",
        connect_timeout: 2,
        follow: 1,
        tls: new_tls,
        features: {
          "cache" => Halite::Cache.new.as(Halite::Feature),
        }
      ))

      old_options.endpoint.should eq(endpoint)
      old_options.headers.should eq(HTTP::Headers{"User-Agent" => "spec"})
      old_options.cookies.size.should eq(0)
      old_options.timeout.connect.should eq(1)
      old_options.timeout.read.should eq(3.2)
      old_options.follow.hops.should eq(2)
      old_options.follow.strict.should be_false
      old_options.params.should eq({"title" => "h1"})
      old_options.form.should eq({"title" => "h2"})
      old_options.json.should eq({"title" => "h3"})
      old_options.raw.should_not be_nil
      old_options.raw.not_nil!.should eq("title=h4")
      old_options.features.size.should eq(1)
      old_options.features["logging"].should be_a(Halite::Logging)
      old_options.tls.not_nil!.should_not eq(new_tls)

      options.endpoint.should eq(URI.parse("https://new.exaple.com"))
      options.headers.should eq(HTTP::Headers{"User-Agent" => "new_spec"})
      options.cookies.size.should eq(0)
      options.timeout.connect.should eq(2)
      options.timeout.read.should be_nil
      options.connect_timeout.should eq(2)
      options.read_timeout.should be_nil
      options.follow.hops.should eq(1)
      options.follow.strict.should be_true
      options.params.should eq({"title" => "1"})
      options.form.should eq({"title" => "2"})
      options.json.should eq({"title" => "3"})
      options.raw.should_not be_nil
      options.raw.not_nil!.should eq("title=4")
      options.tls.not_nil!.should eq(new_tls)
      options.features.size.should eq(2)
      options.features["logging"].should be_a(Halite::Logging)
      options.features["cache"].should be_a(Halite::Cache)
    end

    it "should overwrite exists value of headers from other" do
      options = Halite::Options.new(headers: {private_token: "foo"})
      new_options = options.merge(Halite::Options.new(headers: {private_token: "bar"}))
      new_options.headers.should eq(Halite::Options.new(headers: {private_token: "bar"}).headers)
    end

    it "should merge new headers from other" do
      options = Halite::Options.new(headers: {private_token: "foo"})
      new_options = options.merge(Halite::Options.new(headers: {content_type: "text/html"}))
      new_options.headers.should eq(Halite::Options.new(headers: {private_token: "foo", content_type: "text/html"}).headers)
    end
  end

  describe "#clear!" do
    options = test_options
    options.clear!
    options.endpoint.should be_nil
    options.headers.size.should eq(0)

    options.cookies.should be_a(HTTP::Cookies)
    options.cookies.size.should eq(0)

    options.timeout.should be_a(Halite::Timeout)
    options.timeout.connect.should be_nil
    options.timeout.read.should be_nil
    options.connect_timeout.should be_nil
    options.read_timeout.should be_nil

    options.follow.should be_a(Halite::Follow)
    options.follow.hops.should eq(Halite::Follow::DEFAULT_HOPS)
    options.follow.strict.should eq(Halite::Follow::STRICT)
    options.follow_strict.should eq(Halite::Follow::STRICT)

    options.tls.should be_nil
    options.params.should eq({} of String => Halite::Options::Type)
    options.form.should eq({} of String => Halite::Options::Type)
    options.json.should eq({} of String => Halite::Options::Type)
    options.raw.should be_nil

    options.features.should eq({} of String => Halite::Feature)
  end

  describe "#dup" do
    options = test_options
    new_options = options.dup

    new_options.endpoint = "https://example.com"
    new_options.endpoint.should eq(URI.parse("https://example.com"))
    options.endpoint.should eq(URI.parse("https://spec.example.com"))

    new_options.headers = HTTP::Headers.new
    new_options.headers.empty?.should be_true
    options.headers.size.should eq(1)

    cookies = HTTP::Cookies.new
    cookies << HTTP::Cookie.new("name", "foobar")
    new_options.cookies = cookies
    new_options.cookies.size.should eq(1)
    options.cookies.size.should eq 0

    timeout = Halite::Timeout.new(10, 20)
    new_options.timeout = timeout
    new_options.timeout.should eq(timeout)
    options.timeout.read.should eq(test_options.timeout.read)
    options.timeout.connect.should eq(test_options.timeout.connect)

    follow = Halite::Follow.new(6, true)
    new_options.follow = follow
    new_options.follow.should eq(follow)
    options.follow.hops.should eq(test_options.follow.hops)
    options.follow.strict.should eq(test_options.follow.strict)

    new_options.tls = nil
    new_options.tls.should be_nil
    options.tls.should_not be_nil

    data = {
      "name" => "foo".as(Halite::Options::Type),
    }

    new_options.params = data
    new_options.params.should eq(data)
    options.params.should eq(test_options.params)

    new_options.form = data
    new_options.form.should eq(data)
    options.form.should eq(test_options.form)

    new_options.json = data
    new_options.json.should eq(data)
    options.json.should eq(test_options.json)

    new_options.raw = "foobar"
    new_options.raw.not_nil!.should eq("foobar")
    options.raw.should eq(test_options.raw)

    features = {"cache" => Halite::Cache.new.as(Halite::Feature)}
    new_options.features = features
    new_options.features.size.should eq(1)
    new_options.features["cache"].should be_a(Halite::Cache)
    options.features.size.should eq(1)
    options.features["logging"].should be_a(Halite::Logging)

    new_options.logging = false
    new_options.logging.should be_false
    options.logging.should be_true
  end

  describe "#with_endpoint" do
    it "should overwrite String value" do
      options = Halite::Options.new
      options.with_endpoint("https://with.example.com")

      options.endpoint.should eq(URI.parse("https://with.example.com"))
    end

    it "should overwrite URI value" do
      endpoint = URI.parse("https://with.example.com")
      options = Halite::Options.new(endpoint: "https://new.example.com")
      options.with_endpoint(endpoint)

      options.endpoint.should eq(endpoint)
    end
  end

  describe "#with_headers" do
    it "should overwrite tupled headers" do
      options = Halite::Options.new(headers: {
        private_token: "token",
      })
      options = options.with_headers(private_token: "new", accept: "application/json")

      options.headers["Private-Token"].should eq("new")
      options.headers["Accept"].should eq("application/json")
    end

    it "should overwrite NamedTuped headers" do
      options = Halite::Options.new(headers: {
        private_token: "token",
      })
      options = options.with_headers(private_token: "new", accept: "application/json")

      options.headers["Private-Token"].should eq("new")
      options.headers["Accept"].should eq("application/json")
    end

    it "should overwrite Hash headers" do
      options = Halite::Options.new(headers: {
        private_token: "token",
      })
      options = options.with_headers(private_token: "new", accept: "application/json")

      options.headers["Private-Token"].should eq("new")
      options.headers["Accept"].should eq("application/json")
    end
  end

  describe "#with_cookies" do
    it "should overwrite tupled cookies" do
      options = Halite::Options.new(cookies: {
        "name" => "foo",
      })
      options = options.with_cookies(name: "bar")

      options.cookies["name"].value.should eq("bar")
    end

    it "should overwrite NamedTuple cookies" do
      options = Halite::Options.new(cookies: {
        "name" => "foo",
      })
      options = options.with_cookies({name: "bar"})

      options.cookies["name"].value.should eq("bar")
    end

    it "should overwrite Hash cookies" do
      options = Halite::Options.new(cookies: {
        "name" => "foo",
      })
      options = options.with_cookies({"name" => "bar"})

      options.cookies["name"].value.should eq("bar")
    end
  end

  describe "#with_timeout" do
    it "should overwrite timeout" do
      options = Halite::Options.new(timeout: Halite::Timeout.new(connect: 1, read: 3))
      options = options.with_timeout(read: 4.minutes, connect: 1.2)

      options.timeout.connect.should eq(1.2)
      options.timeout.read.should eq(4.minutes.to_f)
    end
  end

  describe "#with_follow" do
    it "should overwrite follow" do
      options = Halite::Options.new(follow: Halite::Follow.new(1, true))
      options = options.with_follow(follow: 5, strict: false)

      options.follow.hops.should eq(5)
      options.follow.strict.should be_false
    end
  end

  describe "#with_logging" do
    it "should overwrite logging with instance class" do
      options = Halite::Options.new.with_logging(logging: SimpleLogger.new)
      logging = options.features["logging"].as(Halite::Logging)
      logging.writer.should be_a(SimpleLogger)
    end

    it "should overwrite logging with format name" do
      Halite::Logging.register "simple", SimpleLogger

      options = Halite::Options.new.with_logging(format: "simple")
      logging = options.features["logging"].as(Halite::Logging)
      logging.writer.should be_a(SimpleLogger)
    end

    it "should became a file logging" do
      Halite::Logging.register "simple", SimpleLogger

      with_tempfile("halite_logger") do |file|
        options = Halite::Options.new.with_logging(format: "simple", file: file, filemode: "w")
        logging = options.features["logging"].as(Halite::Logging)
        logging.writer.should be_a(SimpleLogger)
      end
    end

    it "throws an exception with unregister logging format" do
      expect_raises Halite::UnRegisterLoggerFormatError do
        Halite::Options.new.with_logging(format: "fake")
      end
    end
  end

  describe "#with_features" do
    it "should use a feature" do
      options = Halite::Options.new.with_features("logging")
      logging = options.features["logging"].as(Halite::Logging)
      logging.writer.should be_a(Halite::Logging::Common)
    end

    it "should use a feature with options" do
      options = Halite::Options.new.with_features("logging", logging: SimpleLogger.new)
      logging = options.features["logging"].as(Halite::Logging)
      logging.writer.should be_a(SimpleLogger)
    end

    it "should use multiple features" do
      Halite.register_feature "simple", SimpleFeature

      options = Halite::Options.new.with_features("logging", "simple")
      logging = options.features["logging"].as(Halite::Logging)
      logging.writer.should be_a(Halite::Logging::Common)

      simple = options.features["simple"].as(SimpleFeature)
      simple.should be_a(SimpleFeature)
    end

    it "throws an exception with unregister feature" do
      expect_raises Halite::UnRegisterFeatureError do
        Halite::Options.new.with_features("fake")
      end
    end
  end

  describe "#clear!" do
    it "should clear setted options" do
      options = Halite::Options.new(
        headers: {
          "private_token" => "token",
        },
        cookies: {
          "name" => "foo",
        },
        params: {"name" => "foo"},
        form: {"name" => "foo"},
        json: {"name" => "foo"},
        timeout: Halite::Timeout.new(1, 3),
        follow: Halite::Follow.new(4, false),
      )
      options.clear!

      options.headers.empty?.should be_true
      options.cookies.empty?.should be_true
      options.params.empty?.should be_true
      options.form.empty?.should be_true
      options.json.empty?.should be_true

      options.timeout.connect.nil?.should be_true
      options.timeout.read.nil?.should be_true

      options.follow.hops.should eq(Halite::Follow::DEFAULT_HOPS)
      options.follow.strict.should eq(Halite::Follow::STRICT)
    end
  end

  describe "alias methods" do
    context "endpoint" do
      it "getter" do
        options = Halite::Options.new(endpoint: "https://with.example.com")
        options.endpoint.should eq(URI.parse("https://with.example.com"))
      end

      it "setter" do
        endpoint_string = "https://with.example.com"
        endpoint = URI.parse(endpoint_string)
        options = Halite::Options.new(endpoint: endpoint_string)
        options.endpoint.should eq(endpoint)

        options = Halite::Options.new(endpoint: endpoint)
        options.endpoint.should eq(endpoint)

        options = Halite::Options.new
        options.endpoint = endpoint_string
        options.endpoint.should eq(endpoint)

        options = Halite::Options.new
        options.endpoint = endpoint
        options.endpoint.should eq(endpoint)
      end
    end


    context "read_timeout alias to timeout.read" do
      it "getter" do
        options = Halite::Options.new(timeout: Halite::Timeout.new(read: 34))
        options.read_timeout.should eq(34)
        options.timeout.read.should eq(34)
      end

      it "setter" do
        options = Halite::Options.new

        options.timeout.read = 12
        options.read_timeout.should eq(12)
        options.timeout.read.should eq(12)

        options.read_timeout = 21
        options.read_timeout.should eq(21)
        options.timeout.read.should eq(21)
      end
    end

    context "connect_timeout alias to timeout.connect" do
      it "getter" do
        options = Halite::Options.new(timeout: Halite::Timeout.new(connect: 34))
        options.timeout.connect.should eq(34)
        options.connect_timeout.should eq(34)
      end

      it "setter" do
        options = Halite::Options.new

        options.timeout.connect = 12
        options.connect_timeout.should eq(12)
        options.timeout.connect.should eq(12)

        options.connect_timeout = 21
        options.connect_timeout.should eq(21)
        options.timeout.connect.should eq(21)
      end
    end

    context "only setter for follow alias to follow.hops" do
      it "setter" do
        options = Halite::Options.new

        options.follow = 2
        options.follow.hops.should eq(2)
      end

      it "getter" do
        options = Halite::Options.new(follow: Halite::Follow.new(3))

        # Can not return integer with follow
        options.follow.hops.should eq(3)
      end
    end

    context "follow_strict alias to follow.strict" do
      it "setter" do
        options = Halite::Options.new

        options.follow_strict = false
        options.follow.strict.should be_false

        options.follow.strict = true
        options.follow.strict.should be_true
      end

      it "getter" do
        options = Halite::Options.new(follow: Halite::Follow.new(strict: false))

        options.follow_strict.should be_false
        options.follow.strict.should be_false
      end
    end
  end
end
