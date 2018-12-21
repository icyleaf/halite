module Halite
  # Proxy struct in request
  struct Proxy
    # Avaiable schemes of proxy
    PROXY_SCHEMES = %w(http)

    # Get proxies from environment
    #
    # It scans the environment for variables named <scheme>_proxy (case-insensitive) and return.
    #
    # ```
    # Halite::Proxy.proxies_from_environment
    # # => {"http" => "http://127.0.0.1:8080", "https" => "https://127.0.0.1:8081", "all" => "socks5://127.0.0.1:8082"}
    # ```
    def self.proxies_from_environment
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
    def self.from_environment
      raise "Not find `all_proxy` in Environment" unless url = proxies_from_environment["all"]?
      new(url: url)
    end

    # Return a `Proxy` with url (only accept http scheme)
    #
    # ```
    # Halite::Proxy.new(url: "http://localhost:8080")
    # ```
    def self.new(*, url : String)
      uri = URI.parse(url)

      unless (scheme = uri.scheme) && PROXY_SCHEMES.includes?(uri.scheme)
        raise "Not support proxy scheme: #{uri.scheme}, avaiables in #{PROXY_SCHEMES}"
      end

      if (host = uri.host) && (port = uri.port)
        return new(host, port, uri.user, uri.password, uri.scheme)
      end

      raise "Invaild proxy url: #{url}"
    end

    getter scheme : String
    getter host, port, username, password, headers

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
    #
    # ### Using custom headers in a proxy
    #
    # ```
    # Halite::Proxy.new("localhost", 8080, headers: HTTP::Headers{"Proxy-Connection" => "keep-alive"})
    # ```
    def initialize(@host : String, @port : Int32, @username : String? = nil,
                   @password : String? = nil, scheme : String? = nil, @headers = HTTP::Headers.new)
      @scheme = scheme || "http"
    end

    def to_headers
      headers = @headers.dup
      using_authenticated? ? headers.merge!(authorization_header) : headers
    end

    def authorization_header
      digest = Base64.strict_encode("#{@username}:#{@password}")
      HTTP::Headers{"Proxy-Authentication" => "Basic #{digest}"}
    end

    def using_authenticated?
      @username && @password
    end
  end
end
