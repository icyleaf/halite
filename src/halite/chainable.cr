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
      def {{ verb.id }}(uri : String, headers : (Hash(String, _) | NamedTuple)? = nil, params : (Hash(String, _) | NamedTuple)? = nil) : Halite::Response
        request {{ verb }}, uri, {
          "headers" => headers,
          "params" => params,
          "form" => nil,
          "json" => nil
        }
      end
    {% end %}

    {% for verb in %w(post patch delete) %}
      # {{ verb.id.capitalize }} a resource
      #
      # ```
      # Halite.{{ verb.id }}("http://httpbin.org/anything", form: {
      #   first_name: "foo",
      #   last_name:  "bar"
      # })
      # ```
      def {{ verb.id }}(uri : String, headers : (Hash(String, _) | NamedTuple)? = nil, params : (Hash(String, _) | NamedTuple)? = nil, form : (Hash(String, _) | NamedTuple)? = nil, json : (Hash(String, _) | NamedTuple)? = nil) : Halite::Response
        request {{ verb }}, uri, {
          "headers" => headers,
          "params" => params,
          "form" => form,
          "json" => json
        }
      end
    {% end %}

    # Make a request with the given Basic authorization header
    #
    # ```
    # Halite.basic_auth("icyleaf", "p@ssw0rd")
    #       .get("http://httpbin.org/get")
    # ```
    #
    # See Also: [http://tools.ietf.org/html/rfc2617](http://tools.ietf.org/html/rfc2617)
    def basic_auth(user : String, pass : String) : Halite::Client
      auth "Basic " + Base64.encode(user + ":" + pass).chomp
    end

    # Make a request with the given Authorization header
    #
    # ```
    # Halite.auth("private-token", "6abaef100b77808ceb7fe26a3bcff1d0")
    #       .get("http://httpbin.org/get")
    # ```
    def auth(value : String) : Halite::Client
      headers({"Authorization" => value})
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
      branch DEFAULT_OPTIONS.with_headers(headers)
    end

    # Make a request with the given headers
    #
    # ```
    # Halite.headers(content_type: "application/json", connection: "keep-alive")
    #       .get("http://httpbin.org/get")
    # ```
    def headers(**kargs) : Halite::Client
      branch DEFAULT_OPTIONS.with_headers(kargs)
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
      branch DEFAULT_OPTIONS.with_cookies(cookies)
    end

    # Make a request with the given cookies
    #
    # ```
    # Halite.cookies(name: "icyleaf", "gender": "male")
    #       .get("http://httpbin.org/get")
    # ```
    def cookies(**kargs) : Halite::Client
      branch DEFAULT_OPTIONS.with_cookies(kargs)
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
    #       .post("http://httpbin.org/post", form: {file: "file.txt"})
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
    #       .post("http://httpbin.org/post", form: {file: "file.txt"})
    # # Or
    # Halite.timeout(3.04, 64)
    #       .get("http://httpbin.org/get")
    # ```
    def timeout(connect : (Int32 | Float64 | Time::Span)?, read : (Int32 | Float64 | Time::Span)?) : Halite::Client
      DEFAULT_OPTIONS.timeout.connect = connect.to_f if connect
      DEFAULT_OPTIONS.timeout.read = read.to_f if read

      branch DEFAULT_OPTIONS
    end

    # Returns `Options` self with automatically following redirects.
    #
    # ```
    # # Automatically following redirects.
    # Halite.follow
    #       .get("http://httpbin.org/relative-redirect/5")
    #
    # # Always redirect with any request methods
    # Halite.follow(strict: false)
    #       .get("http://httpbin.org/get")
    # ```
    def follow(strict = Options::FOLLOW_STRICT) : Halite::Client
      branch DEFAULT_OPTIONS.with_follow(strict: strict)
    end

    # Returns `Options` self with gived max hops of redirect times.
    #
    # ```
    # # Max hops 3 times
    # Halite.follow(3)
    #       .get("http://httpbin.org/relative-redirect/3")
    #
    # # Always redirect with any request methods
    # Halite.follow(4, strict: false)
    #       .get("http://httpbin.org/relative-redirect/4")
    # ```
    def follow(hops : Int32, strict = Options::FOLLOW_STRICT) : Halite::Client
      branch DEFAULT_OPTIONS.with_follow(hops, strict)
    end

    # Make an HTTP request with the given verb
    #
    # ```
    # Halite.request("get", "http://httpbin.org/get", {
    #   "headers" = nil,
    #   "params" => nil,
    #   "form" => nil,
    #   "json" => nil
    # })
    # ```
    private def request(verb : String, uri : String, options : (Hash(String, _) | NamedTuple) = {"headers" => nil, "params" => nil, "form" => nil, "json" => nil}) : Halite::Response
      branch(options).request verb, uri
    end

    # :nodoc:
    DEFAULT_OPTIONS = Halite::Options.new

    # :nodoc:
    private def branch(options : Hash(String, _) | NamedTuple | Options) : Halite::Client
      Halite::Client.new options
    end
  end
end
