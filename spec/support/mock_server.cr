require "http/server"
require "./mock_server/route_handler"

class MockServer < HTTP::Server
  HANDLERS = [MockServer::RouteHandler.new]

  BIND_ADDRESS = "127.0.0.1"
  BIND_PORT    = 18624

  getter running : Bool

  @@INSTANCE = MockServer.new
  def self.instance
    @@INSTANCE
  end

  def initialize
    super(BIND_ADDRESS, BIND_PORT, HANDLERS)
    @running = false
  end

  def listen
    @running = true
    super
  end

  def running?
    @running == true
  end

  def endpoint
    "#{scheme}://#{host}:#{port}"
  end

  def host
    BIND_ADDRESS
  end

  def scheme
    "http"
  end
end
