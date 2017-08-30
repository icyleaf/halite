require "base64"

module Halite
  module Chainable
    {% for verb in %w(get head) %}
      def {{ verb.id }}(url : String, headers : (Hash(String, _) | NamedTuple)? = nil, params : (Hash(String, _) | NamedTuple)? = nil)
        request {{ verb }}, url, {
          "headers" => headers,
          "params" => params,
          "form" => nil,
          "json" => nil
        }
      end
    {% end %}

    {% for verb in %w(post patch delete) %}
      def {{ verb.id }}(url : String, headers : (Hash(String, _) | NamedTuple)? = nil, params : (Hash(String, _) | NamedTuple)? = nil, form : (Hash(String, _) | NamedTuple)? = nil, json : (Hash(String, _) | NamedTuple)? = nil)
        request {{ verb }}, url, {
          "headers" => headers,
          "params" => params,
          "form" => form,
          "json" => json
        }
      end
    {% end %}

    def basic_auth(user : String, pass : String)
      auth "Basic " + Base64.encode(user + ":" + pass).chomp
    end

    def auth(value : String)
      headers({"Authorization" => value})
    end

    def headers(headers : Hash(String, _) | NamedTuple)
      branch default_options.with_headers(headers)
    end

    def headers(**kargs)
      branch default_options.with_headers(kargs)
    end

    def request(verb : String, url : String, options : (Hash(String, _) | NamedTuple) = {} of String => String)
      branch(options).request verb, url
    end

    def default_options
      Halite::Options.new
    end

    def branch(options : Hash(String, _) | NamedTuple | Options)
      Halite::Client.new options
    end
  end
end
