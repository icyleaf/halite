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
  # ```
  # options = Optionns.new({
  #   "headers" = {
  #     "private-token" => "bdf39d82661358f80b31b67e6f89fee4"
  #   }
  # })
  #
  # client = Halite::Client.new(options)
  # client.auth(private_token: "bdf39d82661358f80b31b67e6f89fee4").
  #       .get("http://httpbin.org/get", params: {
  #         name: "icyleaf"
  #       })
  # ```
  class Client
    include Chainable

    property options

    # Instance a new client
    #
    # ```
    # Halite::Client.new({
    #   "headers" => {
    #     "private-token" => "bdf39d82661358f80b31b67e6f89fee4",
    #   },
    # })
    # ```
    def self.new(options : (Hash(String, _) | NamedTuple) = {} of String => String)
      Client.new(Options.new(options))
    end

    # Instance a new client
    #
    # ```
    # Halite::Client.new(headers: {
    #   "private-token" => "bdf39d82661358f80b31b67e6f89fee4",
    # })
    # ```
    def self.new(**options)
      Client.new(Options.new(options))
    end

    # Instance a new client
    #
    # ```
    # options = Halite::Options.new({
    #   "headers" => {
    #     "private-token" => "bdf39d82661358f80b31b67e6f89fee4",
    #   },
    # })
    #
    # client = Halite::Client.new(options)
    # ```
    def initialize(@options : Halite::Options = Options.new)
      @history = [] of Response
    end

    # Make an HTTP request
    def request(verb : String, uri : String, options : (Hash(String, _) | NamedTuple) = {"headers" => nil, "params" => nil, "form" => nil, "json" => nil, "ssl" => nil}) : Halite::Response
      options = @options.merge(options)

      uri = make_request_uri(uri, options)
      body = make_request_body(options)
      headers = make_request_headers(options, body.headers)

      request = Request.new(verb, uri, headers, body.body)
      response = perform(request, options)

      return response if options.follow.hops.zero?

      Redirector.new(request, response, options.follow.hops, options.follow.strict).perform do |req|
        perform(req, options)
      end
    end

    # Perform a single (no follow) HTTP request
    private def perform(request, options) : Halite::Response
      raise RequestError.new("SSL context given for HTTP URI = #{request.uri}") if request.scheme == "http" && options.ssl

      conn = HTTP::Client.new(request.domain, options.ssl)
      conn.connect_timeout = options.timeout.connect.not_nil! if options.timeout.connect
      conn.read_timeout = options.timeout.read.not_nil! if options.timeout.read
      conn_response = conn.exec(request.verb, request.full_path, request.headers, request.body)
      response = Response.new(request.uri, conn_response, @history)

      # Append history of response
      @history << response

      # Merge headers and cookies from response
      @options = merge_option_from_response(options, response)

      response
    rescue ex : IO::Timeout
      raise TimeoutError.new(ex.message)
    rescue ex : Socket::Error | Errno
      raise ConnectionError.new(ex.message)
    end

    # Merges query params if needed
    private def make_request_uri(uri : String, options : Halite::Options) : String
      uri = URI.parse uri
      if params = options.params
        query = HTTP::Params.escape(params)
        uri.query = [uri.query, query].compact.join("&") unless query.empty?
      end

      uri.path = "/" if uri.path.to_s.empty?
      uri.to_s
    end

    # Merges request headers
    private def make_request_headers(options : Halite::Options, content_type : String) : HTTP::Headers
      headers = options.headers
      if !content_type.empty?
        headers.add("Content-Type", content_type)
      end

      headers
    end

    # Merges request headers
    private def make_request_headers(options : Halite::Options, headers : HTTP::Headers?) : HTTP::Headers
      headers = headers ? options.headers.merge!(headers) : options.headers
      options.cookies.add_request_headers(headers)
    end

    # Create the request body object to send
    private def make_request_body(options : Halite::Options) : Halite::Request::Data
      if (form = options.form) && !form.empty?
        return FormData.create(form)
      elsif (hash = options.json) && !hash.empty?
        body = JSON.build do |builder|
          hash.to_json(builder)
        end
        return Halite::Request::Data.new(body, {"Content-Type" => "application/json"})
      end

      Halite::Request::Data.new("", {} of String => String)
    end

    private def merge_option_from_response(options : Halite::Options, response : Halite::Response) : Halite::Options
      return options unless response.headers

      # Store cookies for sessions use
      headers = response.headers.select { |key, _| %w(Cookie, Set-Cookie).includes?(key) }
      options.merge({"headers" => headers})
    end
  end
end
