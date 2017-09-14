module Halite
  class Options
    USER_AGENT = "Halite/#{Halite::VERSION} Crystal/#{Crystal::VERSION}"

    alias Type = Nil | Symbol | String | Int32 | Int64 | Float64 | Bool | File | Array(Type) | Hash(Type, Type)

    getter headers : HTTP::Headers
    getter cookies : HTTP::Cookies
    getter timeout : Timeout

    getter params : Hash(String, Type)?
    getter form : Hash(String, Type)?
    getter json : Hash(String, Type)?

    def initialize(options : (Hash(Type, _) | NamedTuple) = {"headers" => nil, "params" => nil, "form" => nil, "json" => nil})
      @headers = parse_headers(options)
      @cookies = parse_cookies(@headers)
      @timeout = parse_timeout(options)

      @params = parse_params(options)
      @form = parse_form(options)
      @json = parse_json(options)
    end

    # Returns `Options` self with the headers, params, form and json of this hash and other combined.
    def merge(options : Hash(Type, _) | NamedTuple) : Halite::Options
      if headers = parse_headers(options)
        @headers.not_nil!.merge!(headers)
        @cookies.fill_from_headers(@headers)
      end

      if params = parse_params(options)
        @params.not_nil!.merge!(params)
      end

      if form = parse_form(options)
        @form.not_nil!.merge!(form)
      end

      if json = parse_json(options)
        @json.not_nil!.merge!(json)
      end

      self
    end

    # Returns `Options` self with gived headers combined.
    def with_headers(**headers) : Halite::Options
      @headers.not_nil!.merge! parse_headers({"headers" => headers})
      self
    end

    # Returns `Options` self with gived headers combined.
    def with_headers(headers : Hash(Type, _) | NamedTuple) : Halite::Options
      @headers.not_nil!.merge! parse_headers({"headers" => headers})
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
      cookies.each do |c|
        with_cookies(c)
      end

      self
    end

    # Returns `Options` self with gived cookies combined.
    def with_cookies(cookie : HTTP::Cookie) : Halite::Options
      @headers.not_nil!.merge! cookie.to_set_cookie_header
      @cookies.fill_from_headers @headers
      self
    end

    # Returns this collection as a plain Hash.
    def to_h
      {
        "headers" => @headers.to_h,
        "cookies" => @cookies.to_h,
        "params" => @params ? @params.not_nil!.to_h : nil,
        "form" => @form ? @form.not_nil!.to_h : nil,
        "json" => @form ? @json.not_nil!.to_h : nil,
        "connect_timeout" => @timeout.connect,
        "read_timeout" => @timeout.read,
      }
    end

    private def parse_headers(options : (Hash(Type, _) | NamedTuple)) : HTTP::Headers
      headers = HTTP::Headers.new
      if data = options["headers"]?
        headers = HTTP::Headers.escape(data)
      else
        headers = default_headers
      end

      headers
    end

    {% for attr in %w(params form json) %}
      private def parse_{{ attr.id }}(options : Hash(Type, _) | NamedTuple) : Hash(String, Halite::Options::Type)
        new_{{ attr.id }} = {} of String => Type
        if (data = options[{{ attr.id.stringify }}]?) && !data.empty?
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

    private def default_headers : HTTP::Headers
      HTTP::Headers{
        "User-Agent"      => USER_AGENT,
        "Accept-Encoding" => %w(gzip deflate).join(", "),
        "Accept"          => "*/*",
        "Connection"      => "keep-alive",
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
