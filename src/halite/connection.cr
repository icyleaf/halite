require "socket"

module Halite
  class Connection
    # The version of HTTP
    HTTP_VERSION = "HTTP/1.1"

    getter tls : OpenSSL::SSL::Context::Client?
    getter socket : TCPSocket | OpenSSL::SSL::Socket
    getter timeout : Halite::Timeout
    getter proxy : Halite::Proxy?

    def initialize(@request : Halite::Request, options : Halite::Options, @version = HTTP_VERSION)
      @timeout = options.timeout
      @proxy = options.proxy
      @tls = build_tls(tls)
      @socket = build_socket

      verif_proxy_connection if using_proxy?
    end

    def send_request
      @request.headers.merge!(proxy.not_nil!.to_headers) if proxy

      socket << request_line
      @request.headers.each do |key, value|
        socket << key << ": " << value.join(", ") << "\r\n"
      end
      socket << "\r\n"
      socket.flush
    end

    def response
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
      !proxy.nil?
    end

    # Is this request using an authenticated proxy?
    def using_authenticated_proxy?
      proxy.try(&.using_authenticated?) == true
    end

    private def request_line
      request_line @request.verb, @request.full_path(false)
    end

    private def verif_proxy_connection
      connect_using_proxy @socket
      HTTP::Client::Response.from_io(@socket, ignore_body: true, decompress: false) do |response|
        if response.status_code != 200
          raise "Failure to connect http proxy"
        end
      end
    rescue
      raise "Failure to connect http proxy"
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

    private def proxy
      return @proxy if @proxy
      Halite::Proxy.proxies_from_environment.each do |name, url|
        begin
          @proxy ||= Halite::Proxy.new url: url
          return @proxy.not_nil!
        rescue
          # Ignore invalid proxy
          @proxy = nil
          next
        end
      end
    end

    private def build_tls(tls)
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
      socket.read_timeout = @timeout.connect
      socket.sync = false

      {% if !flag?(:without_openssl) %}
        if tls = @tls
          socket = OpenSSL::SSL::Socket::Client.new socket, context: tls, sync_close: true, hostname: @request.host
        end
      {% end %}

      socket
    end

    # Host for tcp socket
    private def socket_host
      using_proxy? ? proxy.not_nil!.host : @request.host
    end

    # Port for tcp socket
    private def socket_port
      using_proxy? ? proxy.not_nil!.port : @request.port
    end
  end
end
