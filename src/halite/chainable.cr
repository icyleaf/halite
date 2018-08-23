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
      def {{ verb.id }}(uri : String,
                        headers : (Hash(String, _) | NamedTuple)? = nil,
                        params : (Hash(String, _) | NamedTuple)? = nil,
                        form : (Hash(String, _) | NamedTuple)? = nil,
                        json : (Hash(String, _) | NamedTuple)? = nil,
                        raw : String? = nil,
                        ssl : OpenSSL::SSL::Context::Client? = nil) : Halite::Response
        request({{ verb }}, uri, {
          "headers" => headers,
          "params" => params,
          "form" => form,
          "json" => json,
          "raw" => raw,
          "ssl" => ssl
        })
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
      def {{ verb.id }}(uri : String,
                        headers : (Hash(String, _) | NamedTuple)? = nil,
                        params : (Hash(String, _) | NamedTuple)? = nil,
                        raw : String? = nil,
                        ssl : OpenSSL::SSL::Context::Client? = nil) : Halite::Response
        request({{ verb }}, uri, {
          "headers" => headers,
          "params" => params,
          "raw" => raw,
          "ssl" => ssl
        })
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
    def follow(strict = Options::Follow::STRICT) : Halite::Client
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
    def follow(hops : Int32, strict = Options::Follow::STRICT) : Halite::Client
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
    # # => halite | 2017-12-13 16:41:32 | GET    | http://httpbin.org/get?name=foobar
    # # => halite | 2017-12-13 16:42:03 | 200    | http://httpbin.org/get?name=foobar | application/json | { ... }
    # ```
    #
    # #### Logging request only
    #
    # ```
    # Halite.logger(response: false)
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    #
    # # => halite | 2017-12-13 16:41:32 | GET    | http://httpbin.org/get?name=foobar
    # ```
    #
    # #### Log use the custom logger
    #
    # Creating the custom logger by integration `Halite::Logger::Adapter` abstract class.
    # here has two methods must be implement: `Halite::Logger::Adapter.request` and `Halite::Logger::Adapter.response`.
    #
    # ```
    # class CustomLogger < Halite::Logger::Adapter
    #   def request(request)
    #     @logger.info "| >> | %s | %s %s" % [request.verb, request.uri, request.body]
    #   end
    #
    #   def response(response)
    #     @logger.info "| << | %s | %s %s" % [response.status_code, response.uri, response.content_type]
    #   end
    # end
    #
    # Halite::Logger.register_adapter "custom", CustomLogger.new
    #
    # Halite.logger(logger: CustomLogger.new)
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    #
    # # Also register name support
    # Halite.logger(adapter: "custom")
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    #
    # # => halite | 2017-12-13 16:40:13 >> | GET | http://httpbin.org/get?name=foobar
    # # => halite | 2017-12-13 16:40:15 << | 200 | http://httpbin.org/get?name=foobar application/json
    # ```
    def logger(logger = Halite::Logger::Common.new, response = true)
      branch(default_options.with_logger(logger, response))
    end

    # Returns `Options` self with gived the filename of logger path.
    #
    # #### JSON-formatted logging
    #
    # ```
    # Halite.logger(adapter: "json")
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    # ```
    #
    # #### create a http request and log to file
    #
    # ```
    # Halite.logger(filename: "/tmp/halite.log")
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    # ```
    #
    # #### Always create new log file and store data to JSON formatted
    #
    # ```
    # Halite.logger(adapter: "json", filename: "/tmp/halite.log", mode: "w")
    #   .get("http://httpbin.org/get", params: {name: "foobar"})
    # ```
    #
    # Check the log file content: **/tmp/halite.log**
    def logger(adapter = "common", filename : String? = nil, mode : String? = nil, response = true)
      branch(default_options.with_logger(adapter, filename, mode, response))
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
    def request(verb : String, uri : String, options : (Hash(String, _) | NamedTuple)) : Halite::Response
      response = branch(options).request(verb, uri)
      DEFAULT_OPTIONS.clear!
      response
    end

    # Make an HTTP request with the given verb
    #
    # ```
    # Halite.request("get", "http://httpbin.org/get")
    # ```
    def request(verb : String, uri : String) : Halite::Response
      response = branch.request(verb, uri)
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

    # :nodoc:
    private def branch(options : Hash(String, _) | NamedTuple | Options) : Halite::Client
      Halite::Client.new(DEFAULT_OPTIONS.merge(options))
    end

    # :nodoc:
    private def branch : Halite::Client
      Halite::Client.new(DEFAULT_OPTIONS)
    end

    # :nodoc:
    DEFAULT_OPTIONS = Halite::Options.new
  end
end
