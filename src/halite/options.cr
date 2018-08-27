require "openssl"
require "./options/*"
module Halite
  # Options class
  #
  # ### Init with splats options
  #
  # ```
  # o = Options.new(
  #   headers: {
  #     user_agent: "foobar"
  #   }
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
    property timeout : Timeout
    property follow : Follow
    property ssl : OpenSSL::SSL::Context::Client?

    property params : Hash(String, Type)
    property form : Hash(String, Type)
    property json : Hash(String, Type)
    property raw : String?

    getter features : Hash(String, Features::Adapter)
    getter logging : Bool
    setter logger : Halite::Logger::Adapter?

    def self.new(headers : (Hash(String, _) | NamedTuple)? = nil,
                 cookies : (Hash(String, _) | NamedTuple)? = nil,
                 params : (Hash(String, _) | NamedTuple)? = nil,
                 form : (Hash(String, _) | NamedTuple)? = nil,
                 json : (Hash(String, _) | NamedTuple)? = nil,
                 raw : String? = nil,
                 connect_timeout : (Int32 | Float64 | Time::Span)? = nil,
                 read_timeout : (Int32 | Float64 | Time::Span)? = nil,
                 follow : Int32? = nil,
                 follow_strict : Bool? = nil,
                 ssl : OpenSSL::SSL::Context::Client? = nil,
                 logging = false,
                 logger = nil)

      timeout = Timeout.new(connect: connect_timeout, read: read_timeout)
      follow = Follow.new(hops: follow, strict: follow_strict)
      new(headers: headers, cookies: cookies, params: params, form: form,
          json: json, raw: raw, timeout: timeout, follow: follow,
          ssl: ssl, logging: logging, logger: logger)
    end

    def initialize(*,
                   headers : (Hash(String, _) | NamedTuple)? = nil,
                   cookies : (Hash(String, _) | NamedTuple)? = nil,
                   params : (Hash(String, _) | NamedTuple)? = nil,
                   form : (Hash(String, _) | NamedTuple)? = nil,
                   json : (Hash(String, _) | NamedTuple)? = nil,
                   @raw : String? = nil,
                   @timeout = Timeout.new,
                   @follow = Follow.new,
                   @ssl : OpenSSL::SSL::Context::Client? = nil,
                   @logging = false,
                   @logger = nil)

      @headers = default_headers.merge!(parse_headers(headers))
      @cookies = parse_cookies(cookies)
      @params = parse_params(params)
      @form = parse_form(form)
      @json = parse_json(json)

      @features = {} of String => Features::Adapter
    end

    # Alias `with_headers` method.
    def with_headers(**with_headers) : Halite::Options
      with_headers(with_headers)
    end

    # Returns `Options` self with gived headers combined.
    def with_headers(headers : Hash(String, _) | NamedTuple) : Halite::Options
      @headers.merge!(parse_headers(headers))
      self
    end

    # Alias `with_cookies` method.
    def with_cookies(**cookies) : Halite::Options
      with_cookies(cookies)
    end

    # Returns `Options` self with gived cookies combined.
    def with_cookies(cookies : Hash(String, _) | NamedTuple) : Halite::Options
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

    # Returns `Options` self with features
    def with_features(features : Hash(String, Features::Adapter))
      features.each do |name, feature|
        with_features(name, feature)
      end
      self
    end

    # Returns `Options` self with features
    def with_features(features : Hash(String, NamedTuple))
      features.each do |name, opts|
        with_features(name, **opts)
      end
      self
    end

    # Returns `Options` self with feature name and options
    def with_features(feature_name : String, **opts)
      with_feature(feature_name, opts)
    end

    # Returns `Options` self with feature name and feature or options
    def with_features(feature_name : String, opts_or_feature : NamedTuple | Features::Adapter)
      raise UnRegisterFeatureError.new("Not avaiable feature: #{feature_name}") unless feature_cls = Features.availables.includes?(feature_name)
      @features[feature_name] = opts_or_feature.is_a?(Features::Adapter) ? opts_or_feature : feature_cls.new(**opts_or_feature)
      self
    end

    # Returns `Logger` self with gived adapter, filename, mode and response.
    def with_logger(adapter = "common", filename : String? = nil, mode : String? = nil, response : Bool = true)
      adapters = Halite::Logger.availables
      raise UnRegisterAdapterError.new("Not avaiable adapter: #{adapter}, avaiables in #{adapters.join(", ")}") unless adapters.includes?(adapter)

      io = if filename && mode
             File.open(filename.not_nil!, mode.not_nil!)
           else
             STDOUT
           end

      logger = Halite::Logger[adapter]
      logger.writer = ::Logger.new(io, logger.level, logger.formatter, logger.progname)

      with_logger(logger: logger, response: response)
    end

    # Returns `Logger` self with gived logger and response.
    def with_logger(logger : Halite::Logger::Adapter = Halite::Logger::Common.new, response : Bool = true)
      @logging = true
      @logger = logger
      logger.level = response ? ::Logger::DEBUG : ::Logger::INFO

      self
    end

    def headers=(headers : (Hash(String, _) | NamedTuple))
      @headers = parse_headers(headers)
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

    # Use logger to dump somthing
    def logger
      raise Error.new("Logging is disable now, set logging = true and try again") unless @logging
      @logger.not_nil!
    end

    # Set logging status
    def logging=(logging : Bool)
      @logging = logging
      @logger = Logger::Common.new unless @logger
    end

    # Return if enable logging
    def logging?
      @logging == true
    end

    # alias `merge` above
    def merge(options : Halite::Options) : Halite::Options
      @headers.merge!(options.headers) if options.headers != default_headers
      @cookies.fill_from_headers(@headers) if @headers

      if options.timeout.connect || options.timeout.read
        @timeout = options.timeout
      end

      if options.follow.updated?
        @follow = options.follow
      end

      @params.merge!(options.params) if options.params
      @form.merge!(options.form) if options.form
      @json.merge!(options.json) if options.json
      @raw = options.raw if options.raw
      @ssl = options.ssl if options.ssl

      self
    end

    # Reset options
    def clear! : Halite::Options
      @headers = default_headers
      @cookies = HTTP::Cookies.new
      @params = {} of String => Type
      @form = {} of String => Type
      @json = {} of String => Type
      @raw = nil
      @timeout = Timeout.new
      @follow = Follow.new
      @ssl = nil

      self
    end

    # Return default headers
    #
    # Auto accept gzip deflate encoding by [HTTP::Client](https://crystal-lang.org/api/0.25.1/HTTP/Client.html)
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
        "raw"             => @raw,
        "connect_timeout" => @timeout.connect,
        "read_timeout"    => @timeout.read,
        "follow"          => @follow.hops,
        "follow_strict"   => @follow.strict,
      }
    end

    private def parse_headers(raw : (Hash(String, _) | NamedTuple | HTTP::Headers)?) : HTTP::Headers
      case raw
      when Hash, NamedTuple
        HTTP::Headers.escape(raw)
      when HTTP::Headers
        raw.as(HTTP::Headers)
      else
        HTTP::Headers.new
      end
    end

    private def parse_cookies(raw : (Hash(String, _) | NamedTuple | HTTP::Cookies)?) : HTTP::Cookies
      cookies = HTTP::Cookies.from_headers(@headers)
      if objects = raw
        objects.each do |key, value|
          cookies[key] = case value
                         when HTTP::Cookie
                           value
                         else
                           value.to_s
                         end
        end
      end
      cookies
    end

    private def parse_cookies(headers : HTTP::Headers) : HTTP::Cookies
      HTTP::Cookies.from_headers(headers)
    end

    {% for attr in %w(params form json) %}
      private def parse_{{ attr.id }}(raw : (Hash(String, _) | NamedTuple)?) : Hash(String, Options::Type)
        new_{{ attr.id }} = {} of String => Type
        return new_{{ attr.id }} unless {{ attr.id }} = raw

        if {{ attr.id }}.responds_to?(:each)
          {{ attr.id }}.each do |k, v|
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
  end
end
