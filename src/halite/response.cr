module Halite
  class Response
    getter uri
    getter history : Array(Response)

    def initialize(@uri : URI, @conn : HTTP::Client::Response, @history = [] of Response)
    end

    delegate version, to: @conn
    delegate status_code, to: @conn
    delegate status_message, to: @conn
    delegate content_type, to: @conn
    delegate success?, to: @conn

    delegate headers, to: @conn
    delegate charset, to: @conn

    delegate body, to: @conn
    delegate body_io, to: @conn

    # Content Length
    def content_length : Int64?
      if value = @conn.headers["Content-Length"]?
        value.to_i64
      end
    end

    def cookies : HTTP::Cookies?
      cookies = @conn.cookies ? @conn.cookies : HTTP::Cookies.from_headers(@conn.headers)

      # Try to fix empty domain
      cookies.map do |cookie|
        cookie.domain = @uri.host unless cookie.domain
        cookie
      end

      cookies
    end

    # Parse response body with corresponding MIME type adapter.
    def parse(name : String? = nil)
      name ||= content_type

      raise Halite::Error.new("No match MIME type: #{name}") unless name
      raise Halite::UnRegisterAdapterError.new("unregister MIME type adapter: #{name}") unless MimeTypes[name]?

      MimeTypes[name].decode to_s
    end

    # Return raw of response
    def to_raw
      io = IO::Memory.new
      @conn.to_io(io)
      io
    end

    # Return status_code, headers and body in a array
    def to_a
      [@conn.status_code, @conn.headers.to_h, to_s]
    end

    # Return String eagerly consume the entire body as a string
    def to_s
      @conn.body? ? @conn.body : @conn.body_io.to_s
    end

    def inspect
      "#<#{self.class} #{version} #{status_code} #{status_message} #{headers.to_h}>"
    end

    def to_s(io)
      io << to_s
    end
  end
end
