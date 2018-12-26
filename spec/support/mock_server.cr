require "http/server"
require "./mock_server/route_handler"

class MockServer < HTTP::Server
  BIND_ADDRESS = "127.0.0.1"
  BIND_PORT    = 18624

  getter running : Bool

  @@instance = MockServer.new

  def self.instance
    @@instance
  end

  def initialize
    super(MockServer::RouteHandler.new)
    @running = false
  end

  def listen
    @running = true
    bind_tcp(BIND_ADDRESS, BIND_PORT)
    super
  end

  def running?
    @running == true
  end

  def endpoint
    "#{scheme}://#{BIND_ADDRESS}:#{BIND_PORT}"
  end

  def scheme
    "http"
  end

  def host
    BIND_ADDRESS
  end

  def port
    BIND_PORT
  end

  def api(path : String = "")
    File.join(endpoint, path)
  end
end
