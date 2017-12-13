require "openssl"

module Halite
  # Options class
  #
  # ### Init with splats options
  #
  # ```
  # o = Options.new(
  #   headers: {
  #     user_agent: "foobar"
  #   },
  # }
  # o.headers.class # => HTTP::Headers
  # o.cookies.class # => HTTP::Cookies
  # ```
  #
  # ### Set/Get timeout
  #
  # Set it with `connect_timeout`/`read_timeout` keys, but get it call `Timeout` class.
  #
  # ```
  # o = Options.new(connect_timeout: 30, read_timeout: 30)
  # o.timeout.connect # => 30.0
  # o.timeout.read    # => 30.0
  # ```
  #
  # ### Set/Get follow
  #
  # Set it with `follow`/`follow_strict` keys, but get it call `Follow` class.
  #
  # ```
  # o = Options.new(follow: 3, follow_strict: false)
  # o.follow.hops   # => 3
  # o.follow.strict # => false
  # ```
  class Options
    # Request user-agent by default
    USER_AGENT = "Halite/#{Halite::VERSION}"

    # Types of options in a Hash
    alias Type = Nil | Symbol | String | Int32 | Int64 | Float64 | Bool | File | Array(Type) | Hash(Type, Type)

    property headers : HTTP::Headers
    property cookies : HTTP::Cookies
    property timeout : Options::Timeout
    property follow : Options::Follow
    property ssl : OpenSSL::SSL::Context::Client?

    property params : Hash(String, Type)
    property form : Hash(String, Type)
    property json : Hash(String, Type)

    property logger : Halite::Logger
    property logging : Bool

    def self.new(headers = nil, cookies = nil, params = nil, form = nil, json = nil,
                 connect_timeout : (Int32 | Float64 | Time::Span)? = nil,
                 read_timeout : (Int32 | Float64 | Time::Span)? = nil,
                 follow : Int32? = nil,
                 follow_strict : Bool? = nil,
                 ssl : OpenSSL::SSL::Context::Client? = nil,
                 logger = nil,
                 logging = nil)

      Options.new({
        "headers"         => headers,
        "cookies"         => cookies,
        "form"            => form,
        "json"            => json,
        "read_timeout"    => read_timeout,
        "connect_timeout" => connect_timeout,
        "follow"          => follow,
        "follow_strict"   => follow_strict,
        "ssl"             => ssl,
        "logger"          => logger,
        "logging"         => logging
      })
    end

    def initialize(options : (Hash(Type, _) | NamedTuple) = {"headers" => nil, "params" => nil, "form" => nil, "json" => nil, "ssl" => nil})
      @headers = default_headers.merge!(parse_headers(options))
      @cookies = parse_cookies(@headers)
      @timeout = parse_timeout(options)
      @follow = parse_follow(options)
      @ssl = parse_ssl(options)

      @params = parse_params(options)
      @form = parse_form(options)
      @json = parse_json(options)

      # @logger = options.fetch("logger", CommonLogger.new).as(CommonLogger)
      # @logging = options["logging"]? ? options["logging"].as(Bool) : false

      @logger = CommonLogger.new
      @logging = false
    end

    # Returns `Options` self with the headers, params, form and json of this hash and other combined.
    def merge(options : Hash(Type, _) | NamedTuple) : Halite::Options
      if headers = parse_headers(options)
        @headers.merge!(headers)
        @cookies.fill_from_headers(@headers)
      end

      if params = parse_params(options)
        @params.merge!(params)
      end

      if form = parse_form(options)
        @form.merge!(form)
      end

      if json = parse_json(options)
        @json.merge!(json)
      end

      if ssl = parse_ssl(options)
        @ssl = ssl
      end

      self
    end

    # alias `merge` above
    def merge(options : Halite::Options) : Halite::Options
      @headers.merge!(options.headers) if options.headers
      @cookies.fill_from_headers(@headers) if @headers

      @ssl = options.ssl if options.ssl

      @params.merge!(options.params) if options.params
      @form.merge!(options.form) if options.form
      @json.merge!(options.json) if options.json

      self
    end

    # Reset options
    def clear! : Halite::Options
      @headers = default_headers
      @cookies = HTTP::Cookies.new
      @timeout = Timeout.new
      @follow = Follow.new
      @ssl = nil

      @params = {} of String => Type
      @form = {} of String => Type
      @json = {} of String => Type

      self
    end

    # Returns `Options` self with gived headers combined.
    def with_headers(**headers) : Halite::Options
      @headers.merge!(parse_headers({"headers" => headers}))
      self
    end

    # Returns `Options` self with gived headers combined.
    def with_headers(headers : Hash(Type, _) | NamedTuple) : Halite::Options
      @headers.merge!(parse_headers({"headers" => headers}))
      self
    end

    # Returns `Options` self with gived cookies combined.
    def with_cookies(cookies : Hash(Type, _) | NamedTuple) : Halite::Options
      cookies.each do |key, value|
        @cookies[key.to_s] = value.to_s
      end

      self
    end

    # Returns `Options` self with gived cookies combined.
    def with_cookies(**cookies) : Halite::Options
      cookies.each do |key, value|
        @cookies[key.to_s] = value.to_s
      end

      self
    end

    # Returns `Options` self with gived cookies combined.
    def with_cookies(cookies : HTTP::Cookies) : Halite::Options
      cookies.each do |cookie|
        with_cookies(cookie)
      end

      self
    end

    # Returns `Options` self with gived cookies combined.
    def with_cookies(cookie : HTTP::Cookie) : Halite::Options
      cookie_header = HTTP::Headers{"Set-Cookie" => cookie.to_set_cookie_header}
      @headers.merge!(cookie_header)
      @cookies.fill_from_headers(@headers)
      self
    end

    # Returns `Options` self with gived max hops of redirect times.
    #
    # ```
    # # Automatically following redirects
    # options.with_follow
    # # A maximum of 3 subsequent redirects
    # options.with_follow(3)
    # # Set subsequent redirects
    # options.with_follow(3)
    # ```
    def with_follow(follow = Follow::MAX_HOPS, strict = Follow::STRICT) : Halite::Options
      @follow.hops = follow
      @follow.strict = strict
      self
    end

    # Returns `Options` self with gived connect, read timeout.
    def with_timeout(connect : (Int32 | Float64 | Time::Span)? = nil, read : (Int32 | Float64 | Time::Span)? = nil) : Halite::Options
      @timeout.connect = connect.to_f if connect
      @timeout.read = read.to_f if read
      self
    end

    def with_logger(filename : String, response = false)
      with_logger(Halite::CommonLogger.new(filename), response)
    end

    def with_logger(logger : Halite::Logger = CommonLogger.new, response = false)
      @logger = logger
      @logger.level = response ? ::Logger::DEBUG : ::Logger::INFO
      @logging = true

      self
    end

    def headers=(headers : (Hash(Type, _) | NamedTuple))
      @headers = parse_headers({"headers" => headers})
    end

    # Alias `Timeout.connect`
    def connect_timeout
      @timeout.connect
    end

    # Alias `Timeout.connect=`
    def connect_timeout=(timeout : Int32 | Float64 | Time::Span)
      @timeout.connect = timeout
    end

    # Alias `Timeout.read`
    def read_timeout
      @timeout.read
    end

    # Alias `Timeout.read=`
    def read_timeout=(timeout : Int32 | Float64 | Time::Span)
      @timeout.read = timeout
    end

    # Alias `Follow.hops=`
    def follow=(hops : Int32)
      @follow.hops = hops
    end

    # Alias `Follow.strict`
    def follow_strict
      @follow.strict
    end

    # Alias `Follow.strict=`
    def follow_strict=(strict : Bool)
      @follow.strict = strict
    end

    # Return if enable logging
    def logging?
      @logging == true
    end

    # Return default headers
    #
    # Auto accept gzip deflate encoding by [HTTP::Client](https://crystal-lang.org/api/0.23.1/HTTP/Client.html)
    def default_headers : HTTP::Headers
      HTTP::Headers{
        "User-Agent" => USER_AGENT,
        "Accept"     => "*/*",
        "Connection" => "keep-alive",
      }
    end

    # Returns this collection as a plain Hash.
    def to_h
      {
        "headers"         => @headers.to_h,
        "cookies"         => @cookies.to_h,
        "params"          => @params ? @params.to_h : nil,
        "form"            => @form ? @form.to_h : nil,
        "json"            => @json ? @json.to_h : nil,
        "connect_timeout" => @timeout.connect,
        "read_timeout"    => @timeout.read,
        "follow"          => @follow.hops,
        "follow_strict"   => @follow.strict,
      }
    end

    private def parse_headers(options : (Hash(Type, _) | NamedTuple)) : HTTP::Headers
      return HTTP::Headers.new unless options["headers"]?

      case headers = options["headers"]
      when Hash, NamedTuple
        HTTP::Headers.escape(headers)
      when HTTP::Headers
        headers
      else
        HTTP::Headers.new
      end
    end

    {% for attr in %w(params form json) %}
      private def parse_{{ attr.id }}(options : Hash(Type, _) | NamedTuple) : Hash(String, Halite::Options::Type)
        new_{{ attr.id }} = {} of String => Type
        if (data = options[{{ attr.id.stringify }}]?) && data.responds_to?(:empty?) && !data.empty?
          data.each do |k, v|
            new_{{ attr.id }}[k.to_s] =
              case v
              when Array
                v.each_with_object([] of Type) do |e, obj|
                  obj << e.as(Type)
                end
              when Hash
                v.each_with_object({} of String => Type) do |(ik, iv), obj|
                  obj[ik.to_s] = iv.as(Type)
                end
              else
                v.as(Type)
              end
          end
        end

        new_{{ attr.id }}
      end
    {% end %}

    private def parse_cookies(headers : HTTP::Headers) : HTTP::Cookies
      HTTP::Cookies.from_headers(headers)
    end

    private def parse_timeout(options : Hash(Type, _) | NamedTuple) : Timeout
      Timeout.new(timeout_value("connect_timeout", options), timeout_value("read_timeout", options))
    end

    private def parse_follow(options : Hash(Type, _) | NamedTuple) : Follow
      hops = options["follow"]?.as(Int32?)
      strict = options["follow_strict"]?.as(Bool?)
      Follow.new(hops, strict)
    end

    private def parse_ssl(options : Hash(Type, _) | NamedTuple) : OpenSSL::SSL::Context::Client?
      options["ssl"]?.as(OpenSSL::SSL::Context::Client?)
    end

    private def timeout_value(key : String, options : Hash(Type, _) | NamedTuple) : Float64?
      if timeout = options[key]?
        case timeout
        when Int32, Time::Span
          timeout.to_f
        when Float64
          timeout
        end
      end
    end

    # Timeout struct
    struct Timeout
      getter connect, read

      def initialize(@connect : Float64? = nil, @read : Float64? = nil)
      end

      def initialize(connect : Time::Span? = nil, read : Time::Span? = nil)
        @connect = connect.seconds
        @read = read.seconds
      end

      def connect=(timeout : Int32 | Float64 | Time::Span)
        @connect = timeout.to_f
      end

      def read=(timeout : Int32 | Float64 | Time::Span)
        @read = timeout.to_f
      end
    end

    struct Follow
      # No follow by default
      DEFAULT_HOPS = 0

      # A maximum of 5 subsequent redirects
      MAX_HOPS = 5

      # Redirector hops policy
      STRICT = true

      property hops : Int32
      property strict : Bool

      def initialize(hops : Int32? = nil, strict : Bool? = nil)
        @hops = hops || DEFAULT_HOPS
        @strict = strict.nil? ? STRICT : strict
      end

      def strict?
        @strict == true
      end
    end
  end
end
