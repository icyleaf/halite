require "spec"
require "./support/mock_server"
require "../src/halite"

def with_tempfile(filename)
  yield File.tempname("halite-spec-logging")
end

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

    Halite.register_feature "append_headers", self
  end
end

module TestInterceptors
  class Mock < Halite::Feature
    def intercept(chain)
      response = Halite::Response.new(chain.request.uri, 400, "mock")
      chain.return(response)
    end

    Halite.register_feature "mock", self
  end

  class AlwaysNotFound < Halite::Feature
    def intercept(chain)
      response = chain.perform
      response = Halite::Response.new(chain.request.uri, 404, response.body, response.headers)
      chain.next(response)
    end

    Halite.register_feature "404", self
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

    Halite.register_feature "powered_by", self
  end
end

class SimpleLogger < Halite::Logging::Abstract
  def request(request)
    @logger.info "request"
  end

  def response(response)
    @logger.info "response"
  end

  Halite::Logging.register "simple", self
end

def fixture_path(file)
  File.join(File.dirname(__FILE__), "fixtures", file)
end

def load_fixture(file)
  File.read_lines(fixture_path(file)).join("\n")
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
