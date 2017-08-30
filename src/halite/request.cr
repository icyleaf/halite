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

    def normalize_uri(uri : String)
      URI.parse(uri)
    end
  end
end
