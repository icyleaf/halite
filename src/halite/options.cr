module Halite
  class Options
    USER_AGENT = "Halite/#{Halite::VERSION} Crystal/#{Crystal::VERSION}"

    alias Type = Nil | Symbol | String | Int32 | Int64 | Float64 | Bool | File | Array(Type) | Hash(Type, Type)

    # property cookies : Halite::Cookies

    property headers : Hash(String, String)?
    property params : Hash(String, Type)?
    property form : Hash(String, Type)?
    property json : Hash(String, Type)?

    def initialize(options : (Hash(Type, _) | NamedTuple) = {"headers" => nil, "params" => nil, "form" => nil, "json" => nil})
      @headers = default_headers.merge(parse_headers(options))
      @params = parse_params(options)
      @form = parse_form(options)
      @json = parse_json(options)

      # @cookies = parse_cookies(@headers)
    end

    def merge(options : Hash(Type, _) | NamedTuple)
      if headers = parse_headers(options)
        @headers.not_nil!.merge! headers
      end

      if params = parse_params(options)
        @params.not_nil!.merge! params
      end

      if form = parse_form(options)
        @form.not_nil!.merge! form
      end

      if json = parse_json(options)
        @json.not_nil!.merge! json
      end

      self
    end

    def with_headers(**headers)
      @headers.not_nil!.merge! parse_headers({"headers" => headers})
      self
    end

    def with_headers(headers : Hash(Type, _) | NamedTuple)
      @headers.not_nil!.merge! parse_headers({"headers" => headers})
      self
    end

    def parse_headers(options : (Hash(Type, _) | NamedTuple))
      new_headers = {} of String => String
      if headers = options["headers"]?
        headers = headers.is_a?(NamedTuple) ? headers.to_h : headers
        headers.as(Hash).each do |k, v|
          new_headers[header_key(k.as(Type))] = v.as(Type).to_s
        end
      end

      new_headers
    end

    {% for attr in %w(params form json) %}
      def parse_{{ attr.id }}(options : Hash(Type, _) | NamedTuple)
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

    def parse_cookies(headers : Halite::Headers)
      Halite::Cookies.from_headers(headers)
    end

    private def header_key(key)
      key.to_s.gsub("_", "-").split("-").map { |v| v.capitalize }.join("-")
    end

    private def default_headers
      {
        "User-Agent"      => USER_AGENT,
        "Accept-Encoding" => %w(gzip deflate).join(", "),
        "Accept"          => "*/*",
        "Connection"      => "keep-alive",
      } of String => String
    end
  end
end
