require "socket"

module Halite
  # A connection to the HTTP server
  class Connection
    # The version of HTTP
    HTTP_VERSION = "HTTP/1.1"

    getter proxy : Halite::Proxy?
    getter tls : OpenSSL::SSL::Context::Client?
    getter timeout : Halite::Timeout
    getter socket : TCPSocket | OpenSSL::SSL::Socket

    getter proxy_response_headers : HTTP::Headers? = nil

    def initialize(@request : Halite::Request, options = Halite::Options.new, @version = HTTP_VERSION)
      raise ConnectionError.new("SSL context given for HTTP URI = #{request.uri}") if @request.uri.http? && options.tls

      @timeout = options.timeout
      @proxy = build_proxy(options.proxy)
      @tls = build_tls(tls, @proxy)
      @socket = build_socket

      verif_proxy_connection if using_proxy?
    end

    def send_request
      append_proxy_authorization_header
      Request::Writer.new(@socket, @request.body, @request.headers, request_line).stream

      # # request line
      # @socket << request_line
      # # request headers
      # @request.headers.each do |key, value|
      #   @socket << key << ": " << value.join(", ") << "\r\n"
      # end
      # @socket << "Content-Length: " << @request.body.bytesize.to_s << "\r\n"
      # @socket << "\r\n"
      # # request body
      # @socket << @request.body << "\r\n"
      # @socket.flush
    end

    def receive_response
      HTTP::Client::Response.from_io @socket
    end

    def close
      @socket.close unless closed?
    end

    def closed?
      @socket.closed?
    end

    # Is this request using proxy?
    def using_proxy?
      !@proxy.nil?
    end

    # Is this request using an authenticated proxy?
    def using_authenticated_proxy?
      @proxy.try(&.using_authenticated?) == true
    end

    private def request_line
      request_line @request.verb, @request.full_path(false)
    end

    private def append_proxy_authorization_header
      if (temp_proxy = @proxy) && (auth_header = temp_proxy.authorization_header)
        @request.headers.merge!(auth_header)
      end
    end

    private def verif_proxy_connection
      connect_using_proxy(@socket)
      HTTP::Client::Response.from_io(@socket, ignore_body: true, decompress: false) do |response|
        @proxy_response_headers = response.headers
        raise "Failure to connect http proxy" if response.status_code != 200
      end
    end

    private def connect_using_proxy(socket)
      request_line = request_line "CONNECT", @request.host, @request.port
      socket << request_line
      socket << "\r\n" << "\r\n"
      socket.flush
    end

    private def request_line(verb : String, host : String, port : Int32, version = @version)
      request_line verb, "#{host}:#{port}", version
    end

    private def request_line(verb : String, uri : String, version = @version)
      String.build do |io|
        io << verb.upcase << ' ' << uri << ' ' << version << "\r\n"
      end
    end

    private def build_proxy(proxy)
      return proxy if proxy

      # Load from environment
      Halite::Proxy.environment_proxies.each do |_, url|
        proxy = Halite::Proxy.new(url: url)
        return proxy
      end
    end

    private def build_tls(tls, proxy)
      # Use ssl context if request scheme is https
      if @request.uri.https?
        ssl_context = OpenSSL::SSL::Context::Client.new
        # Set non-verify mode SSL context if proxy seted false to verify,
        ssl_context.verify_mode = OpenSSL::SSL::VerifyMode::NONE if proxy.try(&.skip_verify?)
        return ssl_context
      end

      case tls
      when true
        OpenSSL::SSL::Context::Client.new
      when OpenSSL::SSL::Context::Client
        tls
      when false
        nil
      end
    end

    private def build_socket
      socket = TCPSocket.new socket_host, socket_port, nil, @timeout.connect
      socket.read_timeout = @timeout.read if @timeout.read
      socket.sync = true
      if context = @tls
        socket = OpenSSL::SSL::Socket::Client.new socket, context: context, sync_close: true, hostname: @request.host
      end
      socket
    rescue ex : Socket::Error | Errno
      if using_proxy?
        raise ProxyError.new("Failure to connect proxy address: '#{socket_host}:#{socket_port}'")
      else
        raise ConnectionError.new(ex.message, ex)
      end
    rescue ex : OpenSSL::SSL::Error
      if (message = ex.message) && message.includes?("certificate verify failed")
        raise SSLError.new("Certificate verify failed", ex)
      else
        raise ex
      end
    end

    # Host for tcp socket
    private def socket_host
      using_proxy? ? @proxy.not_nil!.host : @request.host
    end

    # Port for tcp socket
    private def socket_port
      using_proxy? ? @proxy.not_nil!.port : @request.port
    end
  end
end
