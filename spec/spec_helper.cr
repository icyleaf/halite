require "spec"
require "./support/mock_server"
require "../src/halite"

module TestFeatures
  class Null < Halite::Feature; end

  class AppendHeaders < Halite::Feature
    def request(request)
      request.headers["X-API-Limit"] = "60"
      request
    end

    def response(response)
      response.headers["X-Powered-By"] = "Halite"
      response
    end

    Halite::Features.register "append_headers", self
  end
end

module TestInterceptors
  class Mock < Halite::Feature
    def intercept(chain)
      response = Halite::Response.new(chain.request.uri, 400, "mock")
      chain.return(response)
    end

    Halite::Features.register "mock", self
  end

  class AlwaysNotFound < Halite::Feature
    def intercept(chain)
      response = chain.perform
      response = Halite::Response.new(chain.request.uri, 404, response.body, response.headers)
      chain.next(response)
    end

    Halite::Features.register "404", self
  end

  class PoweredBy < Halite::Feature
    def intercept(chain)
      if response = chain.response
        response.headers["X-Powered-By"] = "Halite"
        chain.return(response)
      else
        chain
      end
    end

    Halite::Features.register "powered_by", self
  end
end

####################
# Start mock server
####################
SERVER = MockServer.new
spawn do
  SERVER.listen
end

# Wait server a moment
sleep 1.milliseconds

# Close server
at_exit do
  SERVER.close
end
