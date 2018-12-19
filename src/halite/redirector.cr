module Halite
  class Redirector
    # HTTP status codes which indicate redirects
    REDIRECT_CODES = [300, 301, 302, 303, 307, 308]

    # Codes which which should raise StateError in strict mode if original
    # request was any of {UNSAFE_VERBS}
    STRICT_SENSITIVE_CODES = [300, 301, 302]

    # Insecure http verbs, which should trigger StateError in strict mode
    # upon {STRICT_SENSITIVE_CODES}
    UNSAFE_VERBS = %w(PUT DELETE POST)

    # Verbs which will remain unchanged upon See Other response.
    SEE_OTHER_ALLOWED_VERBS = %w(GET HEAD)

    def self.new(request : Halite::Request, response : Halite::Response, options : Halite::Options)
      new(request, response, options.follow.hops, options.follow.strict)
    end

    getter strict : Bool
    getter max_hops : Int32

    # Instance a new Redirector
    def initialize(@request : Halite::Request, @response : Halite::Response, @max_hops = 5, @strict = true)
      @visited = [] of String
    end

    # Follows redirects until non-redirect response found
    def perform(&block : Halite::Request -> Halite::Response) : Halite::Response
      if avaiable?
        each_redirect do |request|
          block.call(request)
        end
      end

      @response
    end

    # Loop each redirect request with block call
    def each_redirect(&block : Halite::Request -> Halite::Response)
      while avaiable?
        @visited << "#{@request.verb} #{@request.uri}"

        raise TooManyRedirectsError.new if too_many_hops?
        raise EndlessRedirectError.new if endless_loop?

        @request = redirect_to(@response.headers["Location"]?)
        @response = block.call(@request)
      end
    end

    # Return `true` if it should redirect, else `false`
    def avaiable?
      REDIRECT_CODES.includes?(@response.status_code)
    end

    # Redirect policy for follow
    private def redirect_to(uri : String?)
      raise StateError.new("No found `Location` in headers") unless uri

      verb = @request.verb
      code = @response.status_code

      if UNSAFE_VERBS.includes?(verb) && STRICT_SENSITIVE_CODES.includes?(code)
        raise StateError.new("Can not follow #{code} redirect") if @strict
        verb = "GET"
      end

      verb = "GET" if !SEE_OTHER_ALLOWED_VERBS.includes?(verb) && code == 303
      @request.redirect(uri, verb)
    end

    # Check if we reached max amount of redirect hops
    private def too_many_hops? : Bool
      1 <= @max_hops && @max_hops < @visited.size
    end

    # Check if we got into an endless loop
    def endless_loop?
      2 <= @visited.count(@visited.last)
    end
  end
end
