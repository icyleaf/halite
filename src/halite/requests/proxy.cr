module Halite
  # Proxy struct in request
  struct Proxy
    # Get proxies from environment
    #
    # It scans the environment for variables named <scheme>_proxy (case-insensitive) and return.
    #
    # ```
    # Halite::Proxy.environment_proxies
    # # => {"http" => "http://127.0.0.1:8080", "https" => "https://127.0.0.1:8081", "all" => "socks5://127.0.0.1:8082"}
    # ```
    def self.environment_proxies
      keyword = "_proxy"
      keyword_length = keyword.size + 1
      Hash(String, String).new.tap do |obj|
        ENV.each do |key, value|
          key = key.downcase
          if !value.empty? && key.ends_with?(keyword)
            scheme = key[0..-keyword_length]
            obj[scheme] = value.strip
          end
        end
      end
    end

    # Return a `Proxy` with `all_proxy` value from Environment
    #
    # `all_proxy` is case-insensitive
    def self.from_environment(verify : Bool = true)
      raise "Not find `all_proxy` in Environment" unless url = environment_proxies["all"]?
      new(url: url, verify: verify)
    end

    # Return a `Proxy` with url
    #
    # ```
    # Halite::Proxy.from_url(url: "http://localhost:8080")
    # # Use Basic Auth
    # Halite::Proxy.from_url(url: "http://user:pass@localhost:8080")
    # ```
    def self.new(*, url : String, verify : Bool = true)
      uri = URI.parse(url)
      if (host = uri.host) && (port = uri.port)
        return new(host, port, uri.user, uri.password, verify)
      end

      raise "Invaild proxy url: #{url}"
    end

    getter host, port, username, password

    # Return a `Proxy` with arguments
    #
    # ### Using a proxy
    #
    # ```
    # Halite::Proxy.new("localhost", 8080)
    # ```
    #
    # ### Using authorization
    #
    # ```
    # Halite::Proxy.new("localhost", 8080, "user", "p@ssw0rd")
    # ```
    def initialize(@host : String, @port : Int32, @username : String? = nil,
                   @password : String? = nil, @verify : Bool = true)
    end

    def skip_verify?
      @verify == false
    end

    def authorization_header
      return unless using_authenticated?
      digest = Base64.strict_encode("#{@username}:#{@password}")
      HTTP::Headers{"Proxy-Authentication" => "Basic #{digest}"}
    end

    def using_authenticated?
      !@username.nil? && !@password.nil?
    end
  end
end
