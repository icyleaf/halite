require "base64"

module Halite
  module Chainable
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
                        ssl : OpenSSL::SSL::Context::Client? = nil) : Halite::Response
        request({{ verb }}, uri, options_with(headers, params, form, json, raw, ssl))
      end
    {% end %}

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
                        ssl : OpenSSL::SSL::Context::Client? = nil) : Halite::Response
        request({{ verb }}, uri, options_with(headers, params, raw: raw, ssl: ssl))
      end
    {% end %}

    # Make a request with the given Basic authorization header
    #
    # ```
    # Halite.basic_auth("icyleaf", "p@ssw0rd")
    #   .get("http://httpbin.org/get")
    # ```
    #
    # See Also: [http://tools.ietf.org/html/rfc2617](http://tools.ietf.org/html/rfc2617)
    def basic_auth(user : String, pass : String) : Halite::Client
      auth("Basic " + Base64.encode(user + ":" + pass).chomp)
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
    # cookies = HTTP::Cookies.from_headers(headers)
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
    # ```
    # Halite.timeout(5.5).get("http://httpbin.org/get")
    # # Or
    # Halite.timeout(2.minutes)
    #   .post("http://httpbin.org/post", form: {file: "file.txt"})
    # ```
    def timeout(connect_and_read : Int32 | Float64 | Time::Span) : Halite::Client
      timeout(connect_and_read, connect_and_read)
    end

    # Adds a timeout to the request.
    #
    # How long to wait for the server to send data before giving up, as a int, float or time span.
    # The timeout value will be applied to both the connect and the read timeouts.
    #
    # ```
    # Halite.timeout(3, 3.minutes)
    #   .post("http://httpbin.org/post", form: {file: "file.txt"})
    # # Or
    # Halite.timeout(3.04, 64)
    #   .get("http://httpbin.org/get")
    # ```
    def timeout(connect : (Int32 | Float64 | Time::Span)?, read : (Int32 | Float64 | Time::Span)?) : Halite::Client
      branch(default_options.with_timeout(connect, read))
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
    def follow(strict = Follow::STRICT) : Halite::Client
      branch(default_options.with_follow(strict: strict))
    end

    # Returns `Options` self with gived max hops of redirect times.
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
    def follow(hops : Int32, strict = Follow::STRICT) : Halite::Client
      branch(default_options.with_follow(hops, strict))
    end

    # Returns `Options` self with gived the logger which it integration from `Halite::Logger`.
    #
    # #### Simple logging
    #
    # ```
    # Halite.logger
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
    # Halite.logger(skip_request_body: true, skip_response_body: true)
    # .post("http://httpbin.org/get", form: {image: File.open("halite-logo.png")})
    #
    # # => 2018-08-28 14:33:19 +08:00 | request  | POST   | http://httpbin.org/post
    # # => 2018-08-28 14:33:21 +08:00 | response | 200    | http://httpbin.org/post | 1.61s | application/json
    # ```
    #
    # #### Use custom logger
    #
    # Creating the custom logger by integration `Halite::Features::Logger::Abstract` abstract class.
    # Here has two methods must be implement: `#request` and `#response`.
    #
    # ```
    # class CustomLogger < Halite::Features::Logger::Abstract
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
    # Halite::Logger.register_adapter "custom", CustomLogger.new
    #
    # Halite.logger(logger: CustomLogger.new)
    #       .get("http://httpbin.org/get", params: {name: "foobar"})
    #
    # # We can also call it use format name if you added it.
    # Halite.logger(format: "custom")
    #       .get("http://httpbin.org/get", params: {name: "foobar"})
    #
    # # => 2017-12-13 16:40:13 +08:00 | >> | GET | http://httpbin.org/get?name=foobar
    # # => 2017-12-13 16:40:15 +08:00 | << | 200 | http://httpbin.org/get?name=foobar application/json
    # ```
    def logger(logger = Halite::Features::CommonLogger.new)
      branch(default_options.with_logger(logger))
    end

    # Returns `Options` self with gived the file with the path.
    #
    # #### JSON-formatted logging
    #
    # ```
    # Halite.logger(format: "json")
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    # ```
    #
    # #### create a http request and log to file
    #
    # ```
    # Halite.logger(file: "/tmp/halite.log")
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    # ```
    #
    # #### Always create new log file and store data to JSON formatted
    #
    # ```
    # Halite.logger(format: "json", file: "/tmp/halite.log")
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    # ```
    #
    # Check the log file content: **/tmp/halite.log**
    def logger(format = "common", file : String? = nil, filemode = "a",
               skip_request_body = false, skip_response_body = false,
               skip_benchmark = false, colorize = true)
      opts = {
        format: format,
        file: file,
        filemode: filemode,
        skip_request_body: skip_request_body,
        skip_response_body: skip_response_body,
        skip_benchmark: skip_benchmark,
        colorize: colorize
      }
      branch(default_options.with_logger(**opts))
    end

    # Turn on given features and its options.
    #
    # Available features to review all subclasses of `Halite::Features::Feature`.
    #
    # #### Use json logger
    #
    # ```
    # Halite.use("logger", format: "json")
    #       .get("http://httpbin.org/get", params: {name: "foobar"})
    #
    # # => { ... }
    # ```
    #
    # #### Use common format logger and skip response body
    # ```
    # Halite.use("logger", format: "common", skip_response_body: true)
    #       .get("http://httpbin.org/get", params: {name: "foobar"})
    #
    # # => 2018-08-28 14:58:26 +08:00 | request  | GET    | http://httpbin.org/get
    # # => 2018-08-28 14:58:27 +08:00 | response | 200    | http://httpbin.org/get | 615.8ms | application/json
    # ```
    def use(features : String, **opts)
      branch(default_options.with_features(features, **opts))
    end

    # Turn on given features.
    #
    # Available features to review all subclasses of `Halite::Features::Feature`.
    #
    # ```
    # Halite.use("logger")
    #       .get("http://httpbin.org/get", params: {name: "foobar"})
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
    def request(verb : String, uri : String, options : (Hash(String, _) | NamedTuple | Options)? = nil) : Halite::Response
      client = options ? branch(options) : branch
      response = client.request(verb, uri)
      DEFAULT_OPTIONS.clear!
      response
    end

    private def default_options
      {% if @type.superclass %}
        DEFAULT_OPTIONS
      {% else %}
        DEFAULT_OPTIONS.clear!
      {% end %}
    end

    private def branch(options : Hash(String, _) | NamedTuple | Options) : Halite::Client
      Halite::Client.new(DEFAULT_OPTIONS.merge(options))
    end

    private def branch : Halite::Client
      Halite::Client.new(DEFAULT_OPTIONS)
    end

    private def options_with(headers : (Hash(String, _) | NamedTuple)? = nil,
                             params : (Hash(String, _) | NamedTuple)? = nil,
                             form : (Hash(String, _) | NamedTuple)? = nil,
                             json : (Hash(String, _) | NamedTuple)? = nil,
                             raw : String? = nil,
                             ssl : OpenSSL::SSL::Context::Client? = nil)
      Halite::Options.new(headers: headers, params: params,
        form: form, json: json, raw: raw, ssl: ssl)
    end

    # :nodoc:
    DEFAULT_OPTIONS = Halite::Options.new
  end
end
