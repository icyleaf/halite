module Halite
  class Response
    def initialize(@conn : HTTP::Client::Response)
    end

    delegate status_code, to: @conn
    delegate version, to: @conn
    delegate headers, to: @conn
    delegate cookies, to: @conn
    delegate body, to: @conn
    delegate body_io, to: @conn

    def content_length : Int64?
      if value = @conn.headers["Content-Length"]?
        value.to_i64
      end
    end

    def content_type : String?
      @conn.headers["Content-Type"]?
    end

    def cookies : HTTP::Cookies
      HTTP::Cookies.from_headers(@conn.headers)
    end

    # Return status_code, headers and body in a array
    def to_a : Array(T)
      [@conn.status_code, @conn.headers.to_h, to_s]
    end

    # Return String eagerly consume the entire body as a string
    def to_s : String
      @conn.body? ? @conn.body : @conn.body_io
    end

    def to_s(io) : String
      io << to_s
    end
  end
end
