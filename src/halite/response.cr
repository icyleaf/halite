module Halite
  class Response
    def self.new(uri : URI, status_code : Int32, body : String? = nil, headers = HTTP::Headers.new,
                 status_message = nil, body_io : IO? = nil, version = "HTTP/1.1", history = [] of Halite::Response)
      conn = HTTP::Client::Response.new(status_code, body, headers, status_message, version, body_io)
      new(uri, conn, history)
    end

    getter uri
    getter conn
    getter history : Array(Response)

    def initialize(@uri : URI, @conn : HTTP::Client::Response, @history = [] of Halite::Response)
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

    # Return a `HTTP::Cookies` of parsed cookie headers or else nil.
    def cookies : HTTP::Cookies?
      cookies = @conn.cookies ? @conn.cookies : HTTP::Cookies.from_server_headers(@conn.headers)

      # Try to fix empty domain
      cookies.map do |cookie|
        cookie.domain = @uri.host unless cookie.domain
        cookie
      end

      cookies
    end

    # Return a list of parsed link headers proxies or else nil.
    def links : Hash(String, Halite::HeaderLink)?
      return unless raw = headers["Link"]?

      HeaderLink.parse(raw, uri)
    end

    def rate_limit : Halite::RateLimit?
      RateLimit.parse(headers)
    end

    # Raise `Halite::ClientError`/`Halite::ServerError` if one occurred.
    #
    # - `4XX` raise an `Halite::ClientError` exception
    # - `5XX` raise an `Halite::ServerError` exception
    # - return `nil` with other status code
    #
    # ```
    # Halite.get("https://httpbin.org/status/404").raise_for_status
    # # => Unhandled exception: 404 not found error with url: https://httpbin.org/status/404  (Halite::ClientError)
    #
    # Halite.get("https://httpbin.org/status/500", params: {"foo" => "bar"}).raise_for_status
    # # => Unhandled exception: 500 internal server error error with url: https://httpbin.org/status/500?foo=bar  (Halite::ServerError)
    #
    # Halite.get("https://httpbin.org/status/301").raise_for_status
    # # => nil
    # ```
    def raise_for_status
      if status_code >= 400 && status_code < 500
        raise Halite::ClientError.new(status_code: status_code, uri: uri)
      elsif status_code >= 500 && status_code < 600
        raise Halite::ServerError.new(status_code: status_code, uri: uri)
      end
    end

    # Parse response body with corresponding MIME type adapter.
    def parse(name : String? = nil)
      name ||= content_type
      raise Halite::Error.new("Missing media type") unless name
      raise Halite::UnRegisterMimeTypeError.new("unregister MIME type adapter: #{name}") unless MimeType[name]?
      MimeType[name].decode to_s
    end

    # Return filename if it exists, else `Nil`.
    def filename : String?
      headers["Content-Disposition"]?.try do |value|
        value.split("filename=")[1]
      end
    end

    # Return raw of response
    def to_raw
      io = IO::Memory.new
      @conn.to_io(io)
      io
    end

    # Return status_code, headers and body in a array
    def to_a
      [@conn.status_code, @conn.headers, to_s]
    end

    # Return String eagerly consume the entire body as a string
    def to_s
      @conn.body? ? @conn.body : @conn.body_io.to_s
    end

    def inspect
      "#<#{self.class} #{version} #{status_code} #{status_message} #{headers.to_flat_h}>"
    end

    def to_s(io)
      io << to_s
    end
  end
end
