require "../spec_helper"
require "tempfile"

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
  )
end

describe Halite::Options do
  describe "#initialize" do
    it "should initial with nothing" do
      options = Halite::Options.new
      options.should be_a(Halite::Options)
      options.headers.should eq(HTTP::Headers{"User-Agent" => "Halite/#{Halite::VERSION}", "Accept" => "*/*", "Connection" => "keep-alive"})

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

      options.logging?.should be_false
    end

    it "should initial with original" do
      options = Halite::Options.new(headers: {
        "private_token" => "token",
      },
        timeout: Halite::Timeout.new(connect: 3.2)
      )

      options.should be_a(Halite::Options)
      options.headers.should be_a(HTTP::Headers)
      options.headers["Private-Token"].should eq("token")
      options.timeout.connect.should eq(3.2)
    end

    it "should initial with quick setup" do
      options = Halite::Options.new(headers: {
        private_token: "token",
      },
        connect_timeout: 1.minutes
      )

      options.should be_a(Halite::Options)
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

  describe "#merge" do
    it "should works with Halite::Options" do
      options = test_options.merge(Halite::Options.new(
        headers: {
          user_agent: "spec",
        },
        params: {"title" => "1"},
        form: {"title" => "2"},
        json: {"title" => "3"},
        raw: "title=4",
        connect_timeout: 2,
        follow: 1
      ))

      options.headers.should eq(HTTP::Headers{"User-Agent" => "spec", "Accept" => "*/*", "Connection" => "keep-alive"})
      options.cookies.size.should eq(0)

      options.timeout.connect.should eq(2)
      options.timeout.read.should be_nil
      options.connect_timeout.should eq(2)
      options.read_timeout.should be_nil

      options.follow.hops.should eq(1)
      options.follow.strict.should be_true
      options.follow_strict.should be_true

      options.params.should eq({"title" => "1"})
      options.form.should eq({"title" => "2"})
      options.json.should eq({"title" => "3"})
      options.raw.should_not be_nil
      options.raw.not_nil!.should eq("title=4")
    end
  end

  describe "#clear!" do
    options = test_options
    options.clear!
    options.headers.should eq(HTTP::Headers{"User-Agent" => "Halite/#{Halite::VERSION}", "Accept" => "*/*", "Connection" => "keep-alive"})

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

    options.logging?.should be_false
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
      options.follow.strict.should eq(false)
    end
  end

  describe "#with_logger" do
    it "should overwrite logger with instance class" do
      options = Halite::Options.new.with_logger(logger: SimpleLogger.new)
      logger = options.features["logging"].as(Halite::Logging)
      logger.writer.should be_a(SimpleLogger)
    end

    it "should overwrite logger with format name" do
      Halite::Logging.register "simple", SimpleLogger

      options = Halite::Options.new.with_logger(format: "simple")
      logger = options.features["logging"].as(Halite::Logging)
      logger.writer.should be_a(SimpleLogger)
    end

    it "should became a file logger" do
      Halite::Logging.register "simple", SimpleLogger

      tempfile = Tempfile.new("halite_logger")

      options = Halite::Options.new.with_logger(format: "simple", file: tempfile.path, filemode: "w")
      logger = options.features["logging"].as(Halite::Logging)
      logger.writer.should be_a(SimpleLogger)
    end

    it "throws an exception with unregister logger format" do
      expect_raises Halite::UnRegisterLoggerFormatError do
        Halite::Options.new.with_logger(format: "fake")
      end
    end
  end

  describe "#with_features" do
    it "should use a feature" do
      options = Halite::Options.new.with_features("logging")
      logger = options.features["logging"].as(Halite::Logging)
      logger.writer.should be_a(Halite::Logging::Common)
    end

    it "should use a feature with options" do
      options = Halite::Options.new.with_features("logging", logger: SimpleLogger.new)
      logger = options.features["logging"].as(Halite::Logging)
      logger.writer.should be_a(SimpleLogger)
    end

    it "should use multiple features" do
      Halite.register_feature "simple", SimpleFeature

      options = Halite::Options.new.with_features("logging", "simple")
      logger = options.features["logging"].as(Halite::Logging)
      logger.writer.should be_a(Halite::Logging::Common)

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

      options.headers.should eq(options.default_headers)
      options.cookies.empty?.should eq(true)
      options.params.empty?.should eq(true)
      options.form.empty?.should eq(true)
      options.json.empty?.should eq(true)

      options.timeout.connect.nil?.should eq(true)
      options.timeout.read.nil?.should eq(true)

      options.follow.hops.should eq(Halite::Follow::DEFAULT_HOPS)
      options.follow.strict.should eq(Halite::Follow::STRICT)
    end
  end

  describe "alias methods" do
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
        options.follow.strict.should eq(false)

        options.follow.strict = true
        options.follow.strict.should eq(true)
      end

      it "getter" do
        options = Halite::Options.new(follow: Halite::Follow.new(strict: false))

        options.follow_strict.should eq(false)
        options.follow.strict.should eq(false)
      end
    end
  end
end
