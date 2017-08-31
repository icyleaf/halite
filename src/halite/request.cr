module Halite
  class Request
    getter verb : String
    getter uri : URI
    getter scheme : String?
    getter headers : HTTP::Headers
    getter body : String

    def initialize(verb : String, uri : String, @headers : HTTP::Headers, @body : String?)
      @verb = verb.upcase
      @uri = normalize_uri uri
      if scheme = @uri.scheme
        @scheme = scheme
      end
    end

    # @return [URI] URI with all componentes but query being normalized.
    def normalize_uri(uri : String)
      URI.parse(uri)
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
