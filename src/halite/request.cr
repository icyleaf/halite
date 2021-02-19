require "./requests/*"

module Halite
  class Request
    # Allowed methods
    #
    # See more: [https://github.com/crystal-lang/crystal/blob/863f301cfe9e9757a6bf1a494ab7bf49bfc07a06/src/http/client.cr#L329](https://github.com/crystal-lang/crystal/blob/863f301cfe9e9757a6bf1a494ab7bf49bfc07a06/src/http/client.cr#L329)
    METHODS = %w(GET PUT POST DELETE HEAD PATCH OPTIONS)

    # Allowed schemes
    SCHEMES = %w(http https)

    # Request user-agent by default
    USER_AGENT = "Halite/#{Halite::VERSION}"

    # Default ports of supported schemes
    PORTS = {
      "http"  => 80,
      "https" => 443,
      "ws"    => 80,
      "wss"   => 443,
    }

    # The verb name of request
    getter verb : String

    # The uri of request
    getter uri : URI

    # The scheme name of request
    getter scheme : String

    # The headers of request
    getter headers : HTTP::Headers

    # The payload of request
    getter body : String

    def initialize(verb : String, @uri : URI, @headers : HTTP::Headers = HTTP::Headers.new, @body : String = "")
      @verb = verb.upcase

      raise UnsupportedMethodError.new("Unknown method: #{@verb}") unless METHODS.includes?(@verb)
      raise UnsupportedSchemeError.new("Missing scheme: #{@uri}") unless @uri.scheme

      @scheme = @uri.scheme.not_nil!

      raise UnsupportedSchemeError.new("Unknown scheme: #{@scheme}") unless SCHEMES.includes?(@scheme)

      @headers["Host"] ||= default_host_to_header
      @headers["User-Agent"] ||= USER_AGENT
      @headers["Connection"] ||= "close"
    end

    # Returns new Request with updated uri
    def redirect(uri : String, verb = @verb)
      headers = @headers.dup
      headers.delete("Host")

      Request.new(verb, redirect_uri(domain, uri), headers, body)
    end

    # Return  a`URI` with the scheme, user, password, port and host combined
    def domain
      URI.new(@uri.scheme, @uri.host, @uri.port, "", nil, @uri.user, @uri.password, nil)
    end

    # Return a `String` with the path, query and fragment(omit with argument `with_fragment: false`) combined
    def full_path(with_fragment = true)
      String.build do |str|
        {% if Crystal::VERSION < "0.36.0" %}
          str << @uri.full_path
        {% else %}
          str << @uri.request_target
        {% end %}
        if @uri.fragment
          str << "#" << @uri.fragment
        end
      end
    end

    def host
      @uri.host.not_nil!
    end

    def port
      @uri.port ||= @uri.https? ? 443 : 80
      @uri.port.not_nil!
    end

    # @return `URI` with all components but query being normalized.
    private def normalize_uri(uri : String) : URI
      URI.parse(uri)
    end

    private def default_host_to_header
      PORTS[@scheme] != port ? "#{host}:#{port}" : host
    end

    private def redirect_uri(source : URI, uri : String) : URI
      return source if uri == '/'

      new_uri = URI.parse(uri)
      # return a new uri with source and relative path
      unless new_uri.scheme && new_uri.host
        new_uri = source.dup.tap do |u|
          u.path = (uri[0] == '/') ? uri : "/#{uri}"
        end
      end

      new_uri
    end

    # Request data of body
    struct Data
      getter body, content_type

      def initialize(@body : String, @content_type : String? = nil)
      end
    end
  end
end

class URI
  def http?
    scheme == "http"
  end

  def https?
    scheme == "https"
  end
end
