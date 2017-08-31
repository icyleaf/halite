module Halite
  class Response

    # getter version : String
    # getter code : Int32
    # getter headers : HTTP::Headers
    # getter cookies : HTTP::Cookies?

    def initialize(@conn : HTTP::Client::Response)
      # @version = @conn.version
      # @code = @conn.status_code
      # @headers = @conn.headers
      # @cookies = @conn.cookies
    end

    # forward_missing_to @conn
    delegate status_code, to: @conn
    delegate version, to: @conn
    delegate headers, to: @conn
    delegate cookies, to: @conn
    delegate body, to: @conn
    delegate body_io, to: @conn
  end
end
