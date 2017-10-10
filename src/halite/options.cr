require "openssl"

module Halite
  class Options
    # Request user-agent by default
    USER_AGENT = "Halite/#{Halite::VERSION}"

    # A maximum of 5 subsequent redirects
    FOLLOW_MAX_HOPS = 5

    # Redirector hops policy
    FOLLOW_STRICT = true

    # Types of options in a Hash
    alias Type = Nil | Symbol | String | Int32 | Int64 | Float64 | Bool | File | Array(Type) | Hash(Type, Type)

    property headers : HTTP::Headers
    property cookies : HTTP::Cookies
    property timeout : Timeout
    property follow : Int32
    property follow_strict : Bool

    property params : Hash(String, Type)
    property form : Hash(String, Type)
    property json : Hash(String, Type)

    property ssl : OpenSSL::SSL::Context::Client?

    def initialize(options : (Hash(Type, _) | NamedTuple) = {"headers" => nil, "params" => nil, "form" => nil, "json" => nil, "ssl" => nil})
      @headers = parse_headers(options).merge!(default_headers)
      @cookies = parse_cookies(@headers)
      @timeout = parse_timeout(options)
      @follow = 0 # No follow by default
      @follow_strict = FOLLOW_STRICT

      @params = parse_params(options)
      @form = parse_form(options)
      @json = parse_json(options)

      @ssl = parse_ssl(options)
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

    def merge(options : Halite::Options) : Halite::Options
      @headers.merge!(options.headers) if options.headers
      @cookies.fill_from_headers(@headers) if @headers
      @params.merge!(options.params) if options.params
      @form.merge!(options.form) if options.form
      @json.merge!(options.json) if options.json
      @ssl = options.ssl if options.ssl

      self
    end

    # Reset options
    def clear! : Halite::Options
      @headers = HTTP::Headers.new
      @cookies = HTTP::Cookies.new

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
        @cookies[key.to_s] = values.to_s
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
    def with_follow(follow : Int32 = FOLLOW_MAX_HOPS, strict : Bool = FOLLOW_STRICT) : Halite::Options
      @follow = follow
      @follow_strict = strict
      self
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
      Timeout.new.tap do |timeout|
        timeout.connect = timeout_value("connect_timeout", options)
        timeout.read = timeout_value("read_timeout", options)
      end
    end

    private def parse_ssl(options : Hash(Type, _) | NamedTuple) : OpenSSL::SSL::Context::Client?
      options["ssl"]?.as(OpenSSL::SSL::Context::Client?)
    end

    private def timeout_value(key, options : Hash(Type, _) | NamedTuple)
      if timeout = options[key]?
        case timeout
        when Int32, Time::Span
          timeout.to_f
        when Float64
          timeout
        end
      end
    end

    # Return default headers
    #
    # Auto accept gzip deflate encoding by [HTTP::Client](https://crystal-lang.org/api/0.23.1/HTTP/Client.html)
    private def default_headers : HTTP::Headers
      HTTP::Headers{
        "User-Agent" => USER_AGENT,
        "Accept"     => "*/*",
        "Connection" => "keep-alive",
      }
    end

    # Timeout struct
    struct Timeout
      property connect, read

      def initialize(@connect : Float64? = nil, @read : Float64? = nil)
      end

      def initialize(connect : Time::Span? = nil, read : Time::Span? = nil)
        @connect = connect.seconds
        @read = read.seconds
      end
    end
  end
end
