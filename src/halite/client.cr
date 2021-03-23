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
  #   logging true
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
                 endpoint : (String | URI)? = nil,
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
        endpoint: endpoint,
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
    #   logging true
    # end
    # ```
    def self.new(&block)
      instance = new
      yield_instance = with instance yield
      if yield_instance
        yield_instance.options.merge!(yield_instance.oneshot_options)
        yield_instance.oneshot_options.clear!
        instance = yield_instance
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
    def initialize(@options = Halite::Options.new)
      @history = [] of Response

      DEFAULT_OPTIONS[object_id] = Halite::Options.new
    end

    def finalize
      DEFAULT_OPTIONS.delete(object_id)
    end

    # Make an HTTP request
    def request(verb : String, uri : String, options : Halite::Options? = nil) : Halite::Response
      opts = options ? @options.merge(options.not_nil!) : @options
      request = build_request(verb, uri, opts)
      response = perform_chain(request, opts) do
        perform(request, opts)
      end

      return response if opts.follow.hops.zero?

      Redirector.new(request, response, opts).perform do |req|
        perform(req, opts)
      end
    end

    # Make an HTTP request
    def request(verb : String, uri : String, options : Halite::Options? = nil, &block : Halite::Response ->)
      opts = options ? @options.merge(options.not_nil!) : @options
      request = build_request(verb, uri, opts)
      perform(request, opts, &block)
    end

    # Find interceptor and return `Response` else perform HTTP request.
    private def perform_chain(request : Halite::Request, options : Halite::Options, &block : -> Response)
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

      conn = make_connection(request, options)
      conn_response = conn.exec(request.verb, request.full_path, request.headers, request.body)
      handle_response(request, conn_response, options)
    rescue ex : IO::TimeoutError
      raise TimeoutError.new(ex.message)
    rescue ex : Socket::Error
      raise ConnectionError.new(ex.message)
    end

    # Perform a single (no follow) streaming HTTP request and redirect automatically
    private def perform(request : Halite::Request, options : Halite::Options, &block : Halite::Response ->)
      raise RequestError.new("SSL context given for HTTP URI = #{request.uri}") if request.scheme == "http" && options.tls

      conn = make_connection(request, options)
      conn.exec(request.verb, request.full_path, request.headers, request.body) do |conn_response|
        response = handle_response(request, conn_response, options)
        redirector = Redirector.new(request, response, options)
        if redirector.avaiable?
          redirector.each_redirect do |req|
            perform(req, options, &block)
          end
        else
          block.call(response)
        end

        return response
      end
    end

    # Prepare a HTTP request
    private def build_request(verb : String, uri : String, options : Halite::Options) : Halite::Request
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
    private def make_request_uri(url : String, options : Halite::Options) : URI
      uri = resolve_uri(url, options)
      if params = options.params
        query = HTTP::Params.encode(params)
        uri.query = [uri.query, query].compact.join('&') unless query.empty?
      end

      uri
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

    # Create the http connection
    private def make_connection(request, options)
      conn = HTTP::Client.new(request.domain, options.tls)
      conn.connect_timeout = options.timeout.connect.not_nil! if options.timeout.connect
      conn.read_timeout = options.timeout.read.not_nil! if options.timeout.read
      conn.write_timeout = options.timeout.write.not_nil! if options.timeout.write
      conn
    end

    # Convert HTTP::Client::Response to response and handles response (see below)
    private def handle_response(request, conn_response : HTTP::Client::Response, options) : Halite::Response
      response = Response.new(uri: request.uri, conn: conn_response, history: @history)
      handle_response(response, options)
    end

    # Handles response by reduce the response of feature, add history and update options
    private def handle_response(response, options) : Halite::Response
      response = options.features.reduce(response) do |res, (_, feature)|
        feature.response(res)
      end

      # Append history of response if enable follow
      @history << response unless options.follow.hops.zero?
      store_cookies_from_response(response)
    end

    # Store cookies for sessions use from response
    private def store_cookies_from_response(response : Halite::Response) : Halite::Response
      return response unless response.headers

      @options.with_cookies(HTTP::Cookies.from_server_headers(response.headers))
      response
    end

    # Use in instance/session mode, it will replace same method in `Halite::Chainable`.
    private def branch(options : Halite::Options? = nil) : Halite::Client
      oneshot_options.merge!(options)
      self
    end

    private def resolve_uri(url : String, options : Halite::Options) : URI
      return URI.parse(url) unless endpoint = options.endpoint
      return endpoint if url.empty?

      endpoint.path += '/' unless endpoint.path.ends_with?('/')
      endpoint.resolve(url)
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
