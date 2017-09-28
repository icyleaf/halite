require "http/server"
require "./mock_server/route_handler"

class MockServer < HTTP::Server
  HANDLERS = [MockServer::RouteHandler.new]

  BIND_ADDRESS = "127.0.0.1"
  BIND_PORT    = 18624

  def initialize(**args)
    super(BIND_ADDRESS, BIND_PORT, HANDLERS)
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
