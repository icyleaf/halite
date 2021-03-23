require "base64"

module Halite
  module Chainable
    {% for verb in %w(get head) %}
      # {{ verb.id.capitalize }} a resource
      #
      # ```
      # Halite.{{ verb.id }}("http://httpbin.org/anything", params: {
      #   first_name: "foo",
      #   last_name:  "bar"
      # })
      # ```
      def {{ verb.id }}(uri : String, *,
                        headers : (Hash(String, _) | NamedTuple)? = nil,
                        params : (Hash(String, _) | NamedTuple)? = nil,
                        raw : String? = nil,
                        tls : OpenSSL::SSL::Context::Client? = nil) : Halite::Response
        request({{ verb }}, uri, headers: headers, params: params, raw: raw, tls: tls)
      end

      # {{ verb.id.capitalize }} a streaming resource
      #
      # ```
      # Halite.{{ verb.id }}("http://httpbin.org/anything") do |response|
      #   puts response.status_code
      #   while line = response.body_io.gets
      #     puts line
      #   end
      # end
      # ```
      def {{ verb.id }}(uri : String, *,
                        headers : (Hash(String, _) | NamedTuple)? = nil,
                        params : (Hash(String, _) | NamedTuple)? = nil,
                        raw : String? = nil,
                        tls : OpenSSL::SSL::Context::Client? = nil,
                        &block : Halite::Response ->)
        request({{ verb }}, uri, headers: headers, params: params, raw: raw, tls: tls, &block)
      end
    {% end %}

    {% for verb in %w(put post patch delete options) %}
      # {{ verb.id.capitalize }} a resource
      #
      # ### Request with form data
      #
      # ```
      # Halite.{{ verb.id }}("http://httpbin.org/anything", form: {
      #   first_name: "foo",
      #   last_name:  "bar"
      # })
      # ```
      #
      # ### Request with json data
      #
      # ```
      # Halite.{{ verb.id }}("http://httpbin.org/anything", json: {
      #   first_name: "foo",
      #   last_name:  "bar"
      # })
      # ```
      #
      # ### Request with raw string
      #
      # ```
      # Halite.{{ verb.id }}("http://httpbin.org/anything", raw: "name=Peter+Lee&address=%23123+Happy+Ave&Language=C%2B%2B")
      # ```
      def {{ verb.id }}(uri : String, *,
                        headers : (Hash(String, _) | NamedTuple)? = nil,
                        params : (Hash(String, _) | NamedTuple)? = nil,
                        form : (Hash(String, _) | NamedTuple)? = nil,
                        json : (Hash(String, _) | NamedTuple)? = nil,
                        raw : String? = nil,
                        tls : OpenSSL::SSL::Context::Client? = nil) : Halite::Response
        request({{ verb }}, uri, headers: headers, params: params, form: form, json: json, raw: raw, tls: tls)
      end

      # {{ verb.id.capitalize }} a streaming resource
      #
      # ```
      # Halite.{{ verb.id }}("http://httpbin.org/anything") do |response|
      #   puts response.status_code
      #   while line = response.body_io.gets
      #     puts line
      #   end
      # end
      # ```
      def {{ verb.id }}(uri : String, *,
                        headers : (Hash(String, _) | NamedTuple)? = nil,
                        params : (Hash(String, _) | NamedTuple)? = nil,
                        form : (Hash(String, _) | NamedTuple)? = nil,
                        json : (Hash(String, _) | NamedTuple)? = nil,
                        raw : String? = nil,
                        tls : OpenSSL::SSL::Context::Client? = nil,
                        &block : Halite::Response ->)
        request({{ verb }}, uri, headers: headers, params: params, form: form, json: json, raw: raw, tls: tls, &block)
      end
    {% end %}

    # Adds a endpoint to the request.
    #
    #
    # ```
    # Halite.endpoint("https://httpbin.org")
    #   .get("/get")
    # ```
    def endpoint(endpoint : String | URI) : Halite::Client
      branch(default_options.with_endpoint(endpoint))
    end

    # Make a request with the given Basic authorization header
    #
    # ```
    # Halite.basic_auth("icyleaf", "p@ssw0rd")
    #   .get("http://httpbin.org/get")
    # ```
    #
    # See Also: [http://tools.ietf.org/html/rfc2617](http://tools.ietf.org/html/rfc2617)
    def basic_auth(user : String, pass : String) : Halite::Client
      auth("Basic " + Base64.strict_encode(user + ":" + pass))
    end

    # Make a request with the given Authorization header
    #
    # ```
    # Halite.auth("private-token", "6abaef100b77808ceb7fe26a3bcff1d0")
    #   .get("http://httpbin.org/get")
    # ```
    def auth(value : String) : Halite::Client
      headers({"Authorization" => value})
    end

    # Accept the given MIME type
    #
    # ```
    # Halite.accept("application/json")
    #   .get("http://httpbin.org/get")
    # ```
    def accept(value : String) : Halite::Client
      headers({"Accept" => value})
    end

    # Set requests user agent
    #
    # ```
    # Halite.user_agent("Custom User Agent")
    #   .get("http://httpbin.org/get")
    # ```
    def user_agent(value : String) : Halite::Client
      headers({"User-Agent" => value})
    end

    # Make a request with the given headers
    #
    # ```
    # Halite.headers({"Content-Type", "application/json", "Connection": "keep-alive"})
    #       .get("http://httpbin.org/get")
    # # Or
    # Halite.headers({content_type: "application/json", connection: "keep-alive"})
    #       .get("http://httpbin.org/get")
    # ```
    def headers(headers : Hash(String, _) | NamedTuple) : Halite::Client
      branch(default_options.with_headers(headers))
    end

    # Make a request with the given headers
    #
    # ```
    # Halite.headers(content_type: "application/json", connection: "keep-alive")
    #   .get("http://httpbin.org/get")
    # ```
    def headers(**kargs) : Halite::Client
      branch(default_options.with_headers(kargs))
    end

    # Make a request with the given cookies
    #
    # ```
    # Halite.cookies({"private-token", "6abaef100b77808ceb7fe26a3bcff1d0"})
    #       .get("http://httpbin.org/get")
    # # Or
    # Halite.cookies({private-token: "6abaef100b77808ceb7fe26a3bcff1d0"})
    #       .get("http://httpbin.org/get")
    # ```
    def cookies(cookies : Hash(String, _) | NamedTuple) : Halite::Client
      branch(default_options.with_cookies(cookies))
    end

    # Make a request with the given cookies
    #
    # ```
    # Halite.cookies(name: "icyleaf", "gender": "male")
    #   .get("http://httpbin.org/get")
    # ```
    def cookies(**kargs) : Halite::Client
      branch(default_options.with_cookies(kargs))
    end

    # Make a request with the given cookies
    #
    # ```
    # cookies = HTTP::Cookies.from_client_headers(headers)
    # Halite.cookies(cookies)
    #   .get("http://httpbin.org/get")
    # ```
    def cookies(cookies : HTTP::Cookies) : Halite::Client
      branch(default_options.with_cookies(cookies))
    end

    # Adds a timeout to the request.
    #
    # How long to wait for the server to send data before giving up, as a int, float or time span.
    # The timeout value will be applied to both the connect and the read timeouts.
    #
    # Set `nil` to timeout to ignore timeout.
    #
    # ```
    # Halite.timeout(5.5).get("http://httpbin.org/get")
    # # Or
    # Halite.timeout(2.minutes)
    #   .post("http://httpbin.org/post", form: {file: "file.txt"})
    # ```
    def timeout(timeout : (Int32 | Float64 | Time::Span)?)
      timeout ? timeout(timeout, timeout, timeout) : branch
    end

    # Adds a timeout to the request.
    #
    # How long to wait for the server to send data before giving up, as a int, float or time span.
    # The timeout value will be applied to both the connect and the read timeouts.
    #
    # ```
    # Halite.timeout(3, 3.minutes, 5)
    #   .post("http://httpbin.org/post", form: {file: "file.txt"})
    # # Or
    # Halite.timeout(3.04, 64, 10.0)
    #   .get("http://httpbin.org/get")
    # ```
    def timeout(connect : (Int32 | Float64 | Time::Span)? = nil,
                read : (Int32 | Float64 | Time::Span)? = nil,
                write : (Int32 | Float64 | Time::Span)? = nil)
      branch(default_options.with_timeout(connect, read, write))
    end

    # Returns `Options` self with automatically following redirects.
    #
    # ```
    # # Automatically following redirects.
    # Halite.follow
    #   .get("http://httpbin.org/relative-redirect/5")
    #
    # # Always redirect with any request methods
    # Halite.follow(strict: false)
    #   .get("http://httpbin.org/get")
    # ```
    def follow(strict = Halite::Options::Follow::STRICT) : Halite::Client
      branch(default_options.with_follow(strict: strict))
    end

    # Returns `Options` self with given max hops of redirect times.
    #
    # ```
    # # Max hops 3 times
    # Halite.follow(3)
    #   .get("http://httpbin.org/relative-redirect/3")
    #
    # # Always redirect with any request methods
    # Halite.follow(4, strict: false)
    #   .get("http://httpbin.org/relative-redirect/4")
    # ```
    def follow(hops : Int32, strict = Halite::Options::Follow::STRICT) : Halite::Client
      branch(default_options.with_follow(hops, strict))
    end

    # Returns `Options` self with enable or disable logging.
    #
    # #### Enable logging
    #
    # Same as call `logging` method without any argument.
    #
    # ```
    # Halite.logging.get("http://httpbin.org/get")
    # ```
    #
    # #### Disable logging
    #
    # ```
    # Halite.logging(false).get("http://httpbin.org/get")
    # ```
    def logging(enable : Bool = true)
      options = default_options
      options.logging = enable
      branch(options)
    end

    # Returns `Options` self with given the logging which it integration from `Halite::Logging`.
    #
    # #### Simple logging
    #
    # ```
    # Halite.logging
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    #
    # => 2018-08-28 14:33:19 +08:00 | request  | POST   | http://httpbin.org/post
    # => 2018-08-28 14:33:21 +08:00 | response | 200    | http://httpbin.org/post | 1.61s | application/json
    # { ... }
    # ```
    #
    # #### Logger configuration
    #
    # By default, Halite will logging all outgoing HTTP requests and their responses(without binary stream) to `STDOUT` on DEBUG level.
    # You can configuring the following options:
    #
    # - `skip_request_body`: By default is `false`.
    # - `skip_response_body`: By default is `false`.
    # - `skip_benchmark`: Display elapsed time, by default is `false`.
    # - `colorize`: Enable colorize in terminal, only apply in `common` format, by default is `true`.
    #
    # ```
    # Halite.logging(skip_request_body: true, skip_response_body: true)
    #   .post("http://httpbin.org/get", form: {image: File.open("halite-logo.png")})
    #
    # # => 2018-08-28 14:33:19 +08:00 | request  | POST   | http://httpbin.org/post
    # # => 2018-08-28 14:33:21 +08:00 | response | 200    | http://httpbin.org/post | 1.61s | application/json
    # ```
    #
    # #### Use custom logging
    #
    # Creating the custom logging by integration `Halite::Logging::Abstract` abstract class.
    # Here has two methods must be implement: `#request` and `#response`.
    #
    # ```
    # class CustomLogger < Halite::Logging::Abstract
    #   def request(request)
    #     @logger.info "| >> | %s | %s %s" % [request.verb, request.uri, request.body]
    #   end
    #
    #   def response(response)
    #     @logger.info "| << | %s | %s %s" % [response.status_code, response.uri, response.content_type]
    #   end
    # end
    #
    # # Add to adapter list (optional)
    # Halite::Logging.register_adapter "custom", CustomLogger.new
    #
    # Halite.logging(logging: CustomLogger.new)
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    #
    # # We can also call it use format name if you added it.
    # Halite.logging(format: "custom")
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    #
    # # => 2017-12-13 16:40:13 +08:00 | >> | GET | http://httpbin.org/get?name=foobar
    # # => 2017-12-13 16:40:15 +08:00 | << | 200 | http://httpbin.org/get?name=foobar application/json
    # ```
    def logging(logging : Halite::Logging::Abstract = Halite::Logging::Common.new)
      branch(default_options.with_logging(logging))
    end

    # Returns `Options` self with given the file with the path.
    #
    # #### JSON-formatted logging
    #
    # ```
    # Halite.logging(format: "json")
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    # ```
    #
    # #### create a http request and log to file
    #
    # ```
    # Log.setup("halite.file", backend: Log::IOBackend.new(File.open("/tmp/halite.log", "a")))
    # Halite.logging(for: "halite.file")
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    # ```
    #
    # #### Always create new log file and store data to JSON formatted
    #
    # ```
    # Log.setup("halite.file", backend: Log::IOBackend.new(File.open("/tmp/halite.log", "w"))
    # Halite.logging(for: "halite.file", format: "json")
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    # ```
    #
    # Check the log file content: **/tmp/halite.log**
    def logging(format : String = "common", *, for : String = "halite",
                skip_request_body = false, skip_response_body = false,
                skip_benchmark = false, colorize = true)
      opts = {
        for:                for,
        skip_request_body:  skip_request_body,
        skip_response_body: skip_response_body,
        skip_benchmark:     skip_benchmark,
        colorize:           colorize,
      }
      branch(default_options.with_logging(format, **opts))
    end

    # Turn on given features and its options.
    #
    # Available features to review all subclasses of `Halite::Feature`.
    #
    # #### Use JSON logging
    #
    # ```
    # Halite.use("logging", format: "json")
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    #
    # # => { ... }
    # ```
    #
    # #### Use common format logging and skip response body
    # ```
    # Halite.use("logging", format: "common", skip_response_body: true)
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    #
    # # => 2018-08-28 14:58:26 +08:00 | request  | GET    | http://httpbin.org/get
    # # => 2018-08-28 14:58:27 +08:00 | response | 200    | http://httpbin.org/get | 615.8ms | application/json
    # ```
    def use(feature : String, **opts)
      branch(default_options.with_features(feature, **opts))
    end

    # Turn on given the name of features.
    #
    # Available features to review all subclasses of `Halite::Feature`.
    #
    # ```
    # Halite.use("logging", "your-custom-feature-name")
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    # ```
    def use(*features)
      branch(default_options.with_features(*features))
    end

    # Make an HTTP request with the given verb
    #
    # ```
    # Halite.request("get", "http://httpbin.org/get", {
    #   "headers" = { "user_agent" => "halite" },
    #   "params" => { "nickname" => "foo" },
    #   "form" => { "username" => "bar" },
    # })
    # ```
    def request(verb : String, uri : String, *,
                headers : (Hash(String, _) | NamedTuple)? = nil,
                params : (Hash(String, _) | NamedTuple)? = nil,
                form : (Hash(String, _) | NamedTuple)? = nil,
                json : (Hash(String, _) | NamedTuple)? = nil,
                raw : String? = nil,
                tls : OpenSSL::SSL::Context::Client? = nil) : Halite::Response
      request(verb, uri, options_with(headers, params, form, json, raw, tls))
    end

    # Make an HTTP request with the given verb and options
    #
    # > This method will be executed with oneshot request.
    #
    # ```
    # Halite.request("get", "http://httpbin.org/stream/3", headers: {"user-agent" => "halite"}) do |response|
    #   puts response.status_code
    #   while line = response.body_io.gets
    #     puts line
    #   end
    # end
    # ```
    def request(verb : String, uri : String, *,
                headers : (Hash(String, _) | NamedTuple)? = nil,
                params : (Hash(String, _) | NamedTuple)? = nil,
                form : (Hash(String, _) | NamedTuple)? = nil,
                json : (Hash(String, _) | NamedTuple)? = nil,
                raw : String? = nil,
                tls : OpenSSL::SSL::Context::Client? = nil,
                &block : Halite::Response ->)
      request(verb, uri, options_with(headers, params, form, json, raw, tls), &block)
    end

    # Make an HTTP request with the given verb and options
    #
    # > This method will be executed with oneshot request.
    #
    # ```
    # Halite.request("get", "http://httpbin.org/get", Halite::Options.new(
    #   "headers" = { "user_agent" => "halite" },
    #   "params" => { "nickname" => "foo" },
    #   "form" => { "username" => "bar" },
    # )
    # ```
    def request(verb : String, uri : String, options : Halite::Options? = nil) : Halite::Response
      branch(options).request(verb, uri)
    end

    # Make an HTTP request with the given verb and options
    #
    # > This method will be executed with oneshot request.
    #
    # ```
    # Halite.request("get", "http://httpbin.org/stream/3") do |response|
    #   puts response.status_code
    #   while line = response.body_io.gets
    #     puts line
    #   end
    # end
    # ```
    def request(verb : String, uri : String, options : Halite::Options? = nil, &block : Halite::Response ->)
      branch(options).request(verb, uri, &block)
    end

    private def branch(options : Halite::Options? = nil) : Halite::Client
      options ||= default_options
      Halite::Client.new(options)
    end

    # Use with new instance of Halite::Client to load unique options
    #
    # Note: append options in Halite::Client#initialize and revoke at #finalize
    DEFAULT_OPTIONS = {} of UInt64 => Halite::Options

    private def default_options
      {% if @type.superclass %}
        DEFAULT_OPTIONS[object_id]
      {% else %}
        Halite::Options.new
      {% end %}
    end

    private def options_with(headers : (Hash(String, _) | NamedTuple)? = nil,
                             params : (Hash(String, _) | NamedTuple)? = nil,
                             form : (Hash(String, _) | NamedTuple)? = nil,
                             json : (Hash(String, _) | NamedTuple)? = nil,
                             raw : String? = nil,
                             tls : OpenSSL::SSL::Context::Client? = nil)
      options = Halite::Options.new(headers: headers, params: params, form: form, json: json, raw: raw, tls: tls)
      default_options.merge!(options)
    end
  end
end
