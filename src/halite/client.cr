require "./request"
require "./response"
require "./redirector"

require "http/client"
require "json"

module Halite
  # Clients make requests and receive responses
  #
  # Support all `Chainable` methods.
  #
  # ### Simple setup
  #
  # ```
  # client = Halite::Client.new(headers: {
  #   "private-token" => "bdf39d82661358f80b31b67e6f89fee4"
  # })
  #
  # client.auth(private_token: "bdf39d82661358f80b31b67e6f89fee4").
  #       .get("http://httpbin.org/get", params: {
  #         name: "icyleaf"
  #       })
  # ```
  #
  # ### Setup with block
  #
  # ```
  # client = Halite::Client.new do
  #   basic_auth "name", "foo"
  #   headers content_type: "application/jsong"
  #   read_timeout 3.minutes
  #   logger true
  # end
  # ```
  class Client
    include Chainable

    # Instance a new client
    #
    # ```
    # Halite::Client.new(headers: {"private-token" => "bdf39d82661358f80b31b67e6f89fee4"})
    # ```
    def self.new(*,
                 headers : (Hash(String, _) | NamedTuple)? = nil,
                 cookies : (Hash(String, _) | NamedTuple)? = nil,
                 params : (Hash(String, _) | NamedTuple)? = nil,
                 form : (Hash(String, _) | NamedTuple)? = nil,
                 json : (Hash(String, _) | NamedTuple)? = nil,
                 raw : String? = nil,
                 timeout = Timeout.new,
                 follow = Follow.new,
                 tls : OpenSSL::SSL::Context::Client? = nil)
      new(Options.new(
        headers: headers,
        cookies: cookies,
        params: params,
        form: form,
        json: json,
        raw: raw,
        tls: tls,
        timeout: timeout,
        follow: follow
      ))
    end

    property options

    # Instance a new client with block
    #
    # ```
    # client = Halite::Client.new do
    #   basic_auth "name", "foo"
    #   logger true
    # end
    # ```
    def self.new(&block)
      instance = new
      value = with instance yield
      if value
        value.options.merge!(value.oneshot_options)
        value.oneshot_options.clear!
        instance = value
      end

      instance
    end

    # Instance a new client
    #
    # ```
    # options = Halite::Options.new(headers: {
    #   "private-token" => "bdf39d82661358f80b31b67e6f89fee4",
    # })
    #
    # client = Halite::Client.new(options)
    # ```
    def initialize(@options = Options.new)
      @history = [] of Response
    end

    # Make an HTTP request
    def request(verb : String, uri : String, options : Options? = nil) : Halite::Response
      opts = options ? @options.merge(options.not_nil!) : @options
      request = build_request(verb, uri, opts)
      response = perform(request, opts) do
        perform(request, opts)
      end

      return response if opts.follow.hops.zero?

      Redirector.new(request, response, opts.follow.hops, opts.follow.strict).perform do |req|
        perform(req, opts)
      end
    end

    # Find interceptor and return `Response` else perform HTTP request.
    private def perform(request : Halite::Request, options : Halite::Options, &block : -> Response)
      chain = Feature::Chain.new(request, nil, options, &block)
      options.features.each do |_, feature|
        current_chain = feature.intercept(chain)
        if current_chain.result == Feature::Chain::Result::Next
          chain = current_chain
        elsif current_chain.result == Feature::Chain::Result::Return && (response = current_chain.response)
          return handle_response(response, options)
        end
      end

      # Make sure return if has response with each interceptor
      if response = chain.response
        return handle_response(response, options)
      end

      # Perform original HTTP request if not found any response in interceptors
      block.call
    end

    # Perform a single (no follow) HTTP request
    private def perform(request : Halite::Request, options : Halite::Options) : Halite::Response
      raise RequestError.new("SSL context given for HTTP URI = #{request.uri}") if request.scheme == "http" && options.tls

      conn = HTTP::Client.new(request.domain, options.tls)
      conn.connect_timeout = options.timeout.connect.not_nil! if options.timeout.connect
      conn.read_timeout = options.timeout.read.not_nil! if options.timeout.read
      conn_response = conn.exec(request.verb, request.full_path, request.headers, request.body)
      response = Response.new(uri: request.uri, conn: conn_response, history: @history)
      handle_response(response, options)
    rescue ex : IO::Timeout
      raise TimeoutError.new(ex.message)
    rescue ex : Socket::Error | Errno
      raise ConnectionError.new(ex.message)
    end

    # Prepare a HTTP request
    private def build_request(verb : String, uri : String, options : Options) : Halite::Request
      uri = make_request_uri(uri, options)
      body_data = make_request_body(options)
      headers = make_request_headers(options, body_data.content_type)
      request = Request.new(verb, uri, headers, body_data.body)

      # reset options during onshot request, see `default_options` method at the bottom of file.
      default_options.clear!

      options.features.reduce(request) do |req, (_, feature)|
        feature.request(req)
      end
    end

    # Merges query params if needed
    private def make_request_uri(uri : String, options : Halite::Options) : String
      uri = URI.parse uri
      if params = options.params
        query = HTTP::Params.encode(params)
        uri.query = [uri.query, query].compact.join("&") unless query.empty?
      end

      uri.path = "/" if uri.path.to_s.empty?
      uri.to_s
    end

    # Merges request headers
    private def make_request_headers(options : Halite::Options, content_type : String?) : HTTP::Headers
      headers = options.headers
      if (value = content_type) && !value.empty? && !headers.has_key?("Content-Type")
        headers.add("Content-Type", value)
      end

      # Cookie shards
      options.cookies.add_request_headers(headers)
    end

    # Create the request body object to send
    private def make_request_body(options : Halite::Options) : Halite::Request::Data
      if (form = options.form) && !form.empty?
        FormData.create(form)
      elsif (hash = options.json) && !hash.empty?
        body = JSON.build do |builder|
          hash.to_json(builder)
        end

        Halite::Request::Data.new(body, "application/json")
      elsif (raw = options.raw) && !raw.empty?
        Halite::Request::Data.new(raw, "text/plain")
      else
        Halite::Request::Data.new("")
      end
    end

    # Handles response by reduce the response of feature, add history and update options
    private def handle_response(response, options)
      response = options.features.reduce(response) do |res, (_, feature)|
        feature.response(res)
      end

      # Append history of response if enable follow
      @history << response unless options.follow.hops.zero?
      store_cookies_from_response(response)
    end

    # Store cookies for sessions use from response
    private def store_cookies_from_response(response : Halite::Response)
      return response unless response.headers
      @options.with_cookies(HTTP::Cookies.from_headers(response.headers))
      response
    end

    # Use in instance/session mode, it will replace same method in `Halite::Chainable`.
    private def branch(options : Options? = nil)
      oneshot_options.merge!(options)
      self
    end

    # :nodoc:
    @oneshot_options : Halite::Options?

    # :nodoc:
    #
    # Store options on each request, then it will reset after finish response.
    #
    # > It will called in this class method, so it mark be public but not recommend to users.
    #
    # It make sure never store any gived headers, cookies, query, form, raw and tls
    # during each request in instance/session mode.
    def oneshot_options
      @oneshot_options ||= Halite::Options.new
      @oneshot_options.not_nil!
    end
  end
end
