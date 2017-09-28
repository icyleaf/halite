module Halite
  class Request
    getter verb : String
    getter uri : URI
    getter scheme : String?
    getter headers : HTTP::Headers
    getter body : String

    def initialize(verb : String, uri : String, @headers : HTTP::Headers, @body : String?)
      @verb = verb.upcase
      @uri = normalize_uri(uri)
      if scheme = @uri.scheme
        @scheme = scheme
      end
    end

    # Returns new Request with updated uri
    def redirect(uri : String, verb = @verb)
      headers = self.headers.dup
      headers.delete("Host")

      Request.new(verb, join_uri(domain, uri).to_s, headers, body)
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

    private def join_uri(source : URI, uri : String) : URI
      new_uri = URI.parse(uri)

      # return a new uri with source and relative path
      unless new_uri.scheme && new_uri.host
        new_uri = source.dup.tap do |u|
          u.path = uri
        end
      end

      new_uri
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
