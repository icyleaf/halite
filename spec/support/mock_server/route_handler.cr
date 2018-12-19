class MockServer < HTTP::Server
  class RouteHandler
    include HTTP::Handler

    METHODS = [:get, :post, :put, :delete, :head, :patch, :options]
    ROUTES  = {} of String => (HTTP::Server::Context -> HTTP::Server::Context)

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

    {% for verb in METHODS %}
      def self.{{ verb.id }}(route : String, &block : HTTP::Server::Context -> HTTP::Server::Context)
        ROUTES["{{ verb.id }}:#{route}"] = block
      end
    {% end %}

    def self.any(route : String, &block : HTTP::Server::Context -> HTTP::Server::Context)
      METHODS.each do |method|
        ROUTES["#{method}:#{route}"] = block
      end
    end

    # Any
    any "/anything" do |context|
      body = {
        "verb"    => context.request.method,
        "url"     => context.request.resource,
        "query"   => context.request.query,
        "headers" => context.request.headers.to_flat_h,
      }

      context.response.status_code = 200
      context.response.content_type = "application/json"
      context.response.print body.to_json
      context
    end

    any "/stream" do |context|
      total = context.request.query_params["n"].to_i

      body = {
        "verb"    => context.request.method,
        "url"     => context.request.resource,
        "query"   => context.request.query,
        "headers" => context.request.headers.to_flat_h,
      }

      total.times do |i|
        context.response.puts body.to_json
        context.response.flush
      end

      context
    end

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

    get "/image" do |context|
      path = File.expand_path("../../../../halite-logo.png", __FILE__)
      context.response.content_type = "image/png"
      context.response.content_length = File.size(path)
      context.response.headers["Content-Disposition"] = "attachment; filename=logo.png"
      File.open(path) do |file|
        IO.copy(file, context.response)
      end
      context
    end

    get "/redirect-301" do |context|
      context.response.status_code = 301
      location =
        if context.request.query_params["relative_path"]?
          "/"
        elsif context.request.query_params["relative_path_without_slash"]?
          "sleep"
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

    get "/multi-redirect" do |context|
      context.response.status_code = 302
      if n = context.request.query_params["n"]?
        n = n.to_i
        next_r = if (r = context.request.query_params["r"]?)
                   r.to_i + 1
                 else
                   1
                 end

        if next_r <= n
          location = "/multi-redirect?n=#{n}&r=#{next_r}"
          context.response.headers["Location"] = location
        else
          context.response.status_code = 200
          context.response.print "Finished #{n} redirect"
        end
      else
        context.response.status_code = 200
        context.response.print "Please Set ?n={n} to multi-redirect"
      end

      context
    end

    get "/cookies" do |context|
      context.response.headers["Set-Cookie"] = "foo=bar"
      context.response.print context.request.cookies.map { |c| "#{c.name}: #{c.value}" }.join("\n")

      context
    end

    get "/get-cookies" do |context|
      body = JSON.build do |json|
        json.object do
          context.request.cookies.each do |cookie|
            json.field cookie.name do
              cookie.value.to_json(json)
            end
          end
        end
      end

      context.response.content_type = "application/json"
      context.response.print body

      context
    end

    get "/user_agent" do |context|
      body = context.request.headers["User-Agent"]
      context.response.print body
      context
    end

    # POST
    post "/" do |context|
      context.response.status_code = 200
      context.response.content_type = "text/html"
      context.response.print "<!doctype html><body>Mock Server is running.</body></html>"
      context
    end

    post "/echo-body" do |context|
      body = parse_body(context.request.body)
      context.response.status_code = 200
      context.response.content_length = body.bytesize
      context.response.print body
      context
    end

    post "/form" do |context|
      form = parse_form(context.request.body)
      if form.empty?
        context.response.status_code = 400
        context.response.print "invalid form data! >:E"
      else
        context.response.status_code = 200
        form.each do |k, v|
          context.response.print "#{k}: #{v}\n"
        end
      end

      context
    end

    post "/upload" do |context|
      if multipart?(context.request.headers)
        upload = parse_upload_form(context.request)
        context.response.status_code = 200
        context.response.content_type = "application/json"

        body = JSON.build do |json|
          json.object do
            json.field "params" do
              json.object do
                upload.params.each do |k, v|
                  json.field k, v
                end
              end
            end

            json.field "files" do
              json.object do
                upload.files.each do |k, v|
                  json.field k do
                    if v.is_a?(Array)
                      json.array do
                        v.as(Array).each do |vv|
                          json.object do
                            json.field "filename", vv.filename
                            json.field "body", "[binary file]"
                          end
                        end
                      end
                    else
                      json.object do
                        json.field "filename", v.filename
                        json.field "body", "[binary file]"
                      end
                    end
                  end
                end
              end
            end
          end
        end

        context.response.print body
      else
        context.response.status_code = 400
        context.response.print "invalid form data! >:E"
      end

      context
    end

    post "/sleep" do |context|
      sleep 2

      context.response.status_code = 200
      context.response.print "hello"
      context
    end

    # PUT
    put "/" do |context|
      context.response.status_code = 200
      context.response.content_type = "text/html"
      context.response.print "<!doctype html><body>Mock Server is running.</body></html>"
      context
    end

    # DELETE
    delete "/" do |context|
      context.response.status_code = 200
      context.response.content_type = "text/html"
      context.response.print "<!doctype html><body>Mock Server is running.</body></html>"
      context
    end

    # HEAD
    head "/" do |context|
      context.response.status_code = 200
      context.response.content_type = "text/html"
      context.response.print "<!doctype html><body>Mock Server is running.</body></html>"
      context
    end

    # PATCH
    patch "/" do |context|
      context.response.status_code = 200
      context.response.content_type = "text/html"
      context.response.print "<!doctype html><body>Mock Server is running.</body></html>"
      context
    end

    # OPTIONS
    options "/" do |context|
      context.response.status_code = 200
      context.response.content_type = "text/html"
      context.response.print "<!doctype html><body>Mock Server is running.</body></html>"
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

    private def self.multipart?(headers : HTTP::Headers)
      if content_type = headers["content_type"]?
        return content_type.includes?("multipart/form-data") ? true : false
      end

      false
    end

    private def self.parse_form(body : (IO | String)?) : HTTP::Params
      HTTP::Params.parse(parse_body(body))
    end

    private def self.parse_upload_form(request : HTTP::Request) : UploadParams
      params = HTTP::Params.parse("")
      files = {} of String => HTTP::FormData::Part | Array(HTTP::FormData::Part)

      HTTP::FormData.parse(request) do |part|
        next unless part

        name = part.name
        if part.filename
          if files.has_key?(name) && files[name].is_a?(HTTP::FormData::Part)
            file = files.delete(name).as(HTTP::FormData::Part)
            files[name] = [file, part]
          else
            files[name] = part
          end
        else
          params.add name, part.body.gets_to_end
        end
      end

      UploadParams.new(params, files)
    end

    record UploadParams, params : HTTP::Params, files : Hash(String, HTTP::FormData::Part | Array(HTTP::FormData::Part))
  end
end
