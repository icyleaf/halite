module Halite
  class Request
    # Allowed methods
    #
    # See more: [https://github.com/crystal-lang/crystal/blob/master/src/http/client.cr#L329](https://github.com/crystal-lang/crystal/blob/master/src/http/client.cr#L329)
    METHODS = %w(GET PUT POST DELETE HEAD PATCH)

    # Allowed schemes
    SCHEMES = %w(http https)

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

    def initialize(verb : String, uri : String, @headers : HTTP::Headers = HTTP::Headers.new, @body : String = "")
      @verb = verb.upcase
      @uri = normalize_uri(uri)

      raise UnsupportedMethodError.new("Unknown method: #{@verb}") unless METHODS.includes?(@verb)
      raise UnsupportedSchemeError.new("Missing scheme: #{@uri}") unless @uri.scheme

      @scheme = @uri.scheme.not_nil!

      raise UnsupportedSchemeError.new("Unknown scheme: #{@scheme}") unless SCHEMES.includes?(@scheme)
    end

    # Returns new Request with updated uri
    def redirect(uri : String, verb = @verb)
      headers = @headers.dup
      headers.delete("Host")

      Request.new(verb, redirect_uri(domain, uri), headers, body)
    end

    # @return `URI` with the scheme, user, password, port and host combined
    def domain
      domain = @uri.to_s
      domain = domain.sub(@uri.full_path, "") if @uri.full_path != "/"
      domain = domain.sub("##{@uri.fragment}", "") if @uri.fragment

      URI.parse(domain)
    end

    # @return `String` with the path, query and fragment combined
    def full_path
      String.build do |str|
        str << @uri.full_path
        str << "#" << @uri.fragment if @uri.fragment
      end
    end

    # @return `URI` with all componentes but query being normalized.
    private def normalize_uri(uri : String) : URI
      URI.parse(uri)
    end

    private def redirect_uri(source : URI, uri : String) : String
      return source.to_s if uri == '/'

      new_uri = URI.parse(uri)
      # return a new uri with source and relative path
      unless new_uri.scheme && new_uri.host
        new_uri = source.dup.tap do |u|
          u.path = (uri[0] == '/') ? uri : "/#{uri}"
        end
      end

      new_uri.to_s
    end

    # Request data of body
    struct Data
      getter body : String
      getter headers : HTTP::Headers

      def self.new(body : String, headers : Hash(String, _))
        new(body, HTTP::Headers.escape(headers))
      end

      def initialize(@body : String, @headers : HTTP::Headers)
      end
    end
  end
end
