require "./request"
require "./response"

require "http/client"

module Halite
  class Client
    include Utils
    include Chainable

    @default_options : Halite::Options

    def initialize(@default_options = Optionns.new)
    end

    def initialize(default_options : (Hash(String, _) | NamedTuple) = {} of String => String)
      @default_options = Options.new(default_options)
    end

    def request(verb : String, uri : String, options : (Hash(String, _) | NamedTuple) = {"headers" => nil, "params" => nil, "form" => nil, "json" => nil})
      options = @default_options.merge(options)

      uri = make_halite_uri(uri, options)
      body, content_type = make_halite_body(options)
      headers = make_halite_headers(options, content_type)

      request = Request.new(verb, uri, headers, body)
      perform(request, options)
    end

    def perform(request, options)
      conn = HTTP::Client.exec(request.verb, request.uri, request.headers, request.body)
      Response.new(conn)
    end

    private def make_halite_uri(uri : String, options : Halite::Options)
      uri = URI.parse uri
      if params = options.params
        query = encode_www_form(params)
        uri.query = [uri.query, query].compact.join("&") unless query.empty?
      end

      uri.path = "/" if uri.path.to_s.empty?
      uri.to_s
    end

    private def make_halite_headers(options : Halite::Options, content_type : String)
      HTTP::Headers.new.tap do |builder|
        builder.add "Content-Type", content_type unless content_type.empty?

        if headers = options.headers
          headers.each do |k, v|
            builder.add k.to_s, v.to_s
          end
        end
      end
    end

    private def make_halite_body(options : Halite::Options)
      content_type = ""
      body = ""

      if (form = options.form) && !form.empty?
        body, content_type = FormData.create form
      elsif (hash = options.json) && !hash.empty?
        body = JSON.build do |builder|
          hash.to_json(builder)
        end
        content_type = "application/json"
      end

      [body, content_type]
    end
  end
end
