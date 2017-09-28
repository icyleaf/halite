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

    # GET
    get "/" do |context|
      context.response.status_code = 200

      case context.request.headers["Accept"]?
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

    get "/bytes" do |context|
      bytes = [80, 75, 3, 4, 20, 0, 0, 0, 8, 0, 123, 104, 169, 70, 99, 243, 243]
      context.response.content_type = "application/octet-stream"
      context.response.print bytes.map { |b| b.unsafe_chr }.join

      context
    end

    get "/redirect-301" do |context|
      context.response.status_code = 301
      location =
        if context.request.query_params["relative_path"]?
          "/"
        else
          "http://#{context.request.host_with_port}/"
        end

      context.response.headers["Location"] = location
      context
    end

    get "/redirect-302" do |context|
      context.response.status_code = 302
      location =
      if context.request.query_params["relative_path"]?
        "/"
      else
        "http://#{context.request.host_with_port}/"
      end

      context.response.headers["Location"] = location
      context
    end

    # POST
    post "/echo-body" do |context|
      body = parse_body(context.request.body)
      context.response.status_code = 200
      context.response.content_length = body.bytesize
      context.response.print body
      context
    end

    post "/form" do |context|
      form = parse_form(context.request.body)
      if form["example"] == "testing-form"
        context.response.status_code = 200
        context.response.print "passed :)"
      else
        context.response.status_code = 400
        context.response.print "invalid! >:E"
      end

      context
    end

    post "/sleep" do |context|
      sleep 2

      context.response.status_code = 200
      context.response.print "hello"
      context
    end

    # HEAD
    head "/" do |context|
      context.response.status_code = 200
      context.response.content_type = "text/html"
      context
    end

    private def self.parse_body(body : (IO | String)?) : String
      case body
      when IO
        body.gets_to_end
      when String
        body
      else
        ""
      end
    end

    private def self.parse_form(body : (IO | String)?) : HTTP::Params
      HTTP::Params.parse(parse_body(body))
    end
  end
end
