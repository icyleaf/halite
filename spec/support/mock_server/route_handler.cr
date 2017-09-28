class MockServer < HTTP::Server
  class RouteHandler
    include HTTP::Handler

    ROUTES = {} of String => (HTTP::Server::Context -> HTTP::Server::Context)

    def call(context : HTTP::Server::Context)
      process_route(context)
    end

    def process_route(context : HTTP::Server::Context)
      method = context.request.method.downcase
      path = context.request.path.to_s
      route = "#{method}:#{path}"

      if block = ROUTES[route]?
        block.call(context)
      else
        not_found(context)
      end
    end

    def not_found(context : HTTP::Server::Context)
      context.response.status_code = 404
      context.response.content_type = "text/html"
      context.response.print "Not Found"

      context
    end

    def self.not_found(context : HTTP::Server::Context)
      context.response.status_code = 404
      context.response.content_type = "text/html"
      context.response.print "Not Found"

      context
    end

    {% for verb in [:get, :post, :put, :delete, :head] %}
      def self.{{ verb.id }}(route : String, &block : HTTP::Server::Context -> HTTP::Server::Context) #HTTP::Server::Context))
        ROUTES["{{ verb.id }}:#{route}"] = block
      end
    {% end %}

    get "/" do |context|
      context.response.status_code = 200

      case context.request.headers["Accept"]
      when "application/json"
        context.response.content_type = "application/json"
        context.response.print "{\"json\": true}"
      else
        context.response.content_type = "text/html"
        context.response.print "<!doctype html><body>Mock Server is running.</body></html>"
      end

      context
    end

    get "/sleep" do |context|
      sleep 2

      context.response.status_code = 200
      context.response.print "hello"
      context
    end

    post "/sleep" do |context|
      sleep 2

      context.response.status_code = 200
      context.response.print "hello"
      context
    end

    get "/params" do |context|
      next not_found(context) unless context.request.query == "foo=bar"

      context.response.status_code = 200
      context.response.print "Params!"
      context
    end

    get "/multiple-params" do |context|
      next not_found(context) unless context.request.query_params == HTTP::Params.new({"foo" => ["bar"], "baz" => ["quux"]})

      context.response.status_code = 200
      context.response.print "More Params!"
      context
    end
  end
end
