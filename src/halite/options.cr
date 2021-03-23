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
  # Set it with `connect_timeout`/`read_timeout`/`write_timeout` keys,
  # but get it call `Timeout` class.
  #
  # ```
  # o = Options.new(connect_timeout: 30, read_timeout: 30)
  # o.timeout.connect # => 30.0
  # o.timeout.read    # => 30.0
  # o.timeout.write   # => nil
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
    def self.new(endpoint : (String | URI)? = nil,
                 headers : (Hash(String, _) | NamedTuple)? = nil,
                 cookies : (Hash(String, _) | NamedTuple)? = nil,
                 params : (Hash(String, _) | NamedTuple)? = nil,
                 form : (Hash(String, _) | NamedTuple)? = nil,
                 json : (Hash(String, _) | NamedTuple)? = nil,
                 raw : String? = nil,
                 connect_timeout : (Int32 | Float64 | Time::Span)? = nil,
                 read_timeout : (Int32 | Float64 | Time::Span)? = nil,
                 write_timeout : (Int32 | Float64 | Time::Span)? = nil,
                 follow : Int32? = nil,
                 follow_strict : Bool? = nil,
                 tls : OpenSSL::SSL::Context::Client? = nil,
                 features = {} of String => Feature)
      new(
        endpoint: endpoint,
        headers: headers,
        cookies: cookies,
        params: params,
        form: form,
        json: json,
        raw: raw,
        timeout: Timeout.new(connect: connect_timeout, read: read_timeout, write: write_timeout),
        follow: Follow.new(hops: follow, strict: follow_strict),
        tls: tls,
        features: features
      )
    end

    # Types of options in a Hash
    alias Type = Nil | Symbol | String | Int32 | Int64 | Float64 | Bool | File | Array(Type) | Hash(String, Type)

    property endpoint : URI?
    property headers : HTTP::Headers
    property cookies : HTTP::Cookies
    property timeout : Timeout
    property follow : Follow
    property tls : OpenSSL::SSL::Context::Client?

    property params : Hash(String, Type)
    property form : Hash(String, Type)
    property json : Hash(String, Type)
    property raw : String?

    property features : Hash(String, Feature)

    def initialize(*,
                   endpoint : (String | URI)? = nil,
                   headers : (Hash(String, _) | NamedTuple)? = nil,
                   cookies : (Hash(String, _) | NamedTuple)? = nil,
                   params : (Hash(String, _) | NamedTuple)? = nil,
                   form : (Hash(String, _) | NamedTuple)? = nil,
                   json : (Hash(String, _) | NamedTuple)? = nil,
                   @raw : String? = nil,
                   @timeout = Timeout.new,
                   @follow = Follow.new,
                   @tls : OpenSSL::SSL::Context::Client? = nil,
                   @features = {} of String => Feature)
      @endpoint = parse_endpoint(endpoint)
      @headers = parse_headers(headers)
      @cookies = parse_cookies(cookies)
      @params = parse_params(params)
      @form = parse_form(form)
      @json = parse_json(json)
    end

    def initialize(*,
                   @endpoint : URI?,
                   @headers : HTTP::Headers,
                   @cookies : HTTP::Cookies,
                   @params : Hash(String, Type),
                   @form : Hash(String, Type),
                   @json : Hash(String, Type),
                   @raw : String? = nil,
                   @timeout = Timeout.new,
                   @follow = Follow.new,
                   @tls : OpenSSL::SSL::Context::Client? = nil,
                   @features = {} of String => Feature)
    end

    def with_endpoint(endpoint : String | URI)
      self.endpoint = endpoint
      self
    end

    # Alias `with_headers` method.
    def with_headers(**with_headers) : Halite::Options
      with_headers(with_headers)
    end

    # Returns `Options` self with given headers combined.
    def with_headers(headers : Hash(String, _) | NamedTuple) : Halite::Options
      @headers.merge!(parse_headers(headers))
      self
    end

    # Alias `with_cookies` method.
    def with_cookies(**cookies) : Halite::Options
      with_cookies(cookies)
    end

    # Returns `Options` self with given cookies combined.
    def with_cookies(cookies : Hash(String, _) | NamedTuple) : Halite::Options
      cookies.each do |key, value|
        @cookies[key.to_s] = value.to_s
      end

      self
    end

    # Returns `Options` self with given cookies combined.
    def with_cookies(cookies : HTTP::Cookies) : Halite::Options
      cookies.each do |cookie|
        with_cookies(cookie)
      end

      self
    end

    # Returns `Options` self with given cookies combined.
    def with_cookies(cookie : HTTP::Cookie) : Halite::Options
      cookie_header = HTTP::Headers{"Cookie" => cookie.to_cookie_header}
      @headers.merge!(cookie_header)
      @cookies.fill_from_client_headers(@headers)
      self
    end

    # Returns `Options` self with given max hops of redirect times.
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

    # Returns `Options` self with given connect, read timeout.
    def with_timeout(connect : (Int32 | Float64 | Time::Span)? = nil,
                     read : (Int32 | Float64 | Time::Span)? = nil,
                     write : (Int32 | Float64 | Time::Span)? = nil) : Halite::Options
      @timeout.connect = connect.to_f if connect
      @timeout.read = read.to_f if read
      @timeout.write = write.to_f if write

      self
    end

    # Returns `Options` self with the name of features.
    def with_features(*features)
      features.each do |feature|
        with_features(feature, NamedTuple.new)
      end
      self
    end

    # Returns `Options` self with feature name and options.
    def with_features(feature_name : String, **opts)
      with_features(feature_name, opts)
    end

    # Returns `Options` self with feature name and options.
    def with_features(name : String, opts : NamedTuple)
      raise UnRegisterFeatureError.new("Not available feature: #{name}") unless klass = Halite.feature?(name)
      @features[name] = klass.new(**opts)
      self
    end

    # Returns `Options` self with feature name and feature.
    def with_features(name : String, feature : Feature)
      @features[name] = feature
      self
    end

    # Returns `Options` iitself with given format and the options of format.
    def with_logging(format : String, **opts)
      raise UnRegisterLoggerFormatError.new("Not available logging format: #{format}") unless format_cls = Logging[format]?
      with_logging(format_cls.new(**opts))
    end

    # Returns `Options` self with given logging, depend on `with_features`.
    def with_logging(logging : Halite::Logging::Abstract)
      with_features("logging", logging: logging)
      self
    end

    # Set endpoint of request
    def endpoint=(endpoint : String)
      @endpoint = URI.parse(endpoint)
    end

    # Set headers of request
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

    # Alias `Timeout.write`
    def write_timeout
      @timeout.write
    end

    # Alias `Timeout.write=`
    def write_timeout=(timeout : Int32 | Float64 | Time::Span)
      @timeout.write = timeout
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

    # Get logging status
    def logging : Bool
      !@features.values.select { |v| v.is_a?(Halite::Logging) }.empty?
    end

    # Quick enable logging
    #
    # By defaults, use `Logging::Common` as logging output.
    def logging=(enable : Bool)
      if enable
        with_features("logging") unless logging
      else
        @features.delete("logging")
      end
    end

    # Merge with other `Options` and return new `Halite::Options`
    def merge(other : Halite::Options) : Halite::Options
      options = Halite::Options.new
      options.merge!(dup)
      options.merge!(other)
      options
    end

    # Merge with other `Options` and return self
    def merge!(other : Halite::Options) : Halite::Options
      @endpoint = other.endpoint if other.endpoint

      @headers.merge!(other.headers)

      other.cookies.each do |cookie|
        @cookies << cookie
      end if other.cookies != @cookies

      if other.timeout.connect || other.timeout.read || other.timeout.write
        @timeout = other.timeout
      end

      if other.follow.updated?
        @follow = other.follow
      end

      @features.merge!(other.features) unless other.features.empty?
      @params.merge!(other.params) if other.params
      @form.merge!(other.form) if other.form
      @json.merge!(other.json) if other.json
      @raw = other.raw if other.raw
      @tls = other.tls if other.tls

      self
    end

    # Reset options
    def clear! : Halite::Options
      @endpoint = nil
      @headers = HTTP::Headers.new
      @cookies = HTTP::Cookies.new
      @params = {} of String => Type
      @form = {} of String => Type
      @json = {} of String => Type
      @raw = nil
      @timeout = Timeout.new
      @follow = Follow.new
      @features = {} of String => Feature
      @tls = nil

      self
    end

    # Produces a shallow copy of obj—the instance variables of obj are copied,
    # but not the objects they reference. dup copies the tainted state of obj.
    def dup
      Halite::Options.new(
        endpoint: @endpoint,
        headers: @headers.dup,
        cookies: @cookies,
        params: @params,
        form: @form,
        json: @json,
        raw: @raw,
        timeout: @timeout,
        follow: @follow,
        features: @features,
        tls: @tls
      )
    end

    # Returns this collection as a plain Hash.
    def to_h
      {
        "endpoint"        => @endpoint,
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

    private def parse_endpoint(endpoint : (String | URI)?) : URI?
      case endpoint
      when String
        URI.parse(endpoint)
      when URI
        endpoint.as(URI)
      else
        nil
      end
    end

    private def parse_headers(raw : (Hash(String, _) | NamedTuple | HTTP::Headers)?) : HTTP::Headers
      case raw
      when Hash, NamedTuple
        HTTP::Headers.encode(raw)
      when HTTP::Headers
        raw.as(HTTP::Headers)
      else
        HTTP::Headers.new
      end
    end

    private def parse_cookies(raw : (Hash(String, _) | NamedTuple | HTTP::Cookies)?) : HTTP::Cookies
      cookies = HTTP::Cookies.from_client_headers(@headers)
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
      cookies = HTTP::Cookies.from_client_headers(headers)
    end

    {% for attr in %w(params form json) %}
      private def parse_{{ attr.id }}(raw : (Hash(String, _) | NamedTuple)?) : Hash(String, Options::Type)
        new_{{ attr.id }} = {} of String => Type
        return new_{{ attr.id }} unless {{ attr.id }} = raw

        if {{ attr.id }}.responds_to?(:each)
          {{ attr.id }}.each do |key, value|
            new_{{ attr.id }}[key.to_s] = case value
                                          when Array
                                            cast_hash(value.as(Array))
                                          when Hash
                                            cast_hash(value.as(Hash))
                                          when NamedTuple
                                            cast_hash(value.as(NamedTuple))
                                          when Type
                                            value
                                          else
                                            value.as(Type)
                                          end
          end
        end

        new_{{ attr.id }}
      end
    {% end %}

    private def cast_hash(raw : Array) : Options::Type
      raw.each_with_object([] of Type) do |value, obj|
        obj << case value
        when Array
          cast_hash(value.as(Array))
        when Hash
          cast_hash(value.as(Hash))
        when NamedTuple
          cast_hash(value.as(NamedTuple))
        else
          value.as(Type)
        end
      end.as(Type)
    end

    private def cast_hash(raw : Hash) : Options::Type
      raw.each_with_object({} of String => Type) do |(key, value), obj|
        if key.responds_to?(:to_s)
          obj[key.to_s] = case value
                          when Array
                            cast_hash(value.as(Array))
                          when Hash
                            cast_hash(value.as(Hash))
                          when NamedTuple
                            cast_hash(value.as(NamedTuple))
                          else
                            value.as(Type)
                          end
        end
      end.as(Type)
    end

    private def cast_hash(raw : NamedTuple) : Options::Type
      cast_hash(raw.to_h)
    end
  end
end
