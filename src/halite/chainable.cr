require "base64"

module Halite
  module Chainable
    {% for verb in %w(get head) %}
      # {{ verb.id.capitalize }} a resource
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
      # require "halite"
      #
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
    # See Also: [http://tools.ietf.org/html/rfc2617](http://tools.ietf.org/html/rfc2617)
    def basic_auth(user : String, pass : String) : Halite::Client
      auth "Basic " + Base64.encode(user + ":" + pass).chomp
    end

    # Make a request with the given Authorization header
    def auth(value : String) : Halite::Client
      headers({"Authorization" => value})
    end

    # Make a request with the given headers
    def headers(headers : Hash(String, _) | NamedTuple) : Halite::Client
      branch DEFAULT_OPTIONS.with_headers(headers)
    end

    # Make a request with the given headers
    def headers(**kargs) : Halite::Client
      branch DEFAULT_OPTIONS.with_headers(kargs)
    end

    def cookies(cookies : Hash(String, _) | NamedTuple) : Halite::Client
      branch DEFAULT_OPTIONS.with_cookies(cookies)
    end

    def cookies(**kargs) : Halite::Client
      branch DEFAULT_OPTIONS.with_cookies(kargs)
    end

    # Make an HTTP request with the given verb
    def request(verb : String, uri : String, options : (Hash(String, _) | NamedTuple) = {"headers" => nil, "params" => nil, "form" => nil, "json" => nil}) : Halite::Response
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
