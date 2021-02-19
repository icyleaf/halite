require "json"

class Halite::Logging
  # JSON logging format
  #
  # Instance variables to check `Halite::Logging::Abstract`.
  #
  # In JSON format, if you set skip some key, it will return `false`.
  #
  # ```
  # Halite.use("logging", logging: Halite::Logging::JSON.new(skip_request_body: true))
  #   .get("http://httpbin.org/get")
  #
  # # Or
  # Halite.logging(format: "json", skip_request_body: true)
  #   .get("http://httpbin.org/get")
  # ```
  #
  # Log will look like:
  #
  # ```
  # {
  #   "created_at": "2018-08-31T16:53:57+08:00:00",
  #   "entry":      {
  #     "request": {
  #       "body":      "",
  #       "headers":   {...},
  #       "method":    "GET",
  #       "url":       "http://httpbin.org/anything",
  #       "timestamp": "2018-08-31T16:53:59+08:00:00",
  #     },
  #     "response": {
  #       "body":         false,
  #       "header":       {...},
  #       "status_code":  200,
  #       "http_version": "HTTP/1.1",
  #       "timestamp":    "2018-08-31T16:53:59+08:00:00",
  #     },
  #   },
  # }
  # ```
  class JSON < Abstract
    @request : Request? = nil
    @response : Response? = nil

    def request(request)
      @request_time = Time.utc
      @request = Request.new(request, @skip_request_body)
    end

    def response(response)
      @response = Response.new(response, @skip_response_body)
      @logger.info { raw }
    end

    private def raw
      elapsed : String? = nil
      if !@skip_benchmark && (request_time = @request_time)
        elapsed = human_time(Time.utc - request_time)
      end

      {
        "created_at" => Helper.to_rfc3339(@request_time.not_nil!),
        "elapsed"    => elapsed,
        "entry"      => {
          "request"  => @request.not_nil!.to_h,
          "response" => @response.not_nil!.to_h,
        },
      }.to_pretty_json
    end

    # :nodoc:
    private struct Request
      def initialize(@request : Halite::Request, @skip_body = false)
      end

      def to_h
        {
          "body"      => @skip_body ? false : @request.body,
          "headers"   => @request.headers.to_flat_h,
          "method"    => @request.verb,
          "url"       => @request.uri.to_s,
          "timestamp" => Helper.to_rfc3339(Time.utc),
        }
      end
    end

    # :nodoc:
    private struct Response
      def initialize(@response : Halite::Response, @skip_body = false)
      end

      def to_h
        {
          "body"         => @skip_body ? false : @response.body,
          "header"       => @response.headers.to_flat_h,
          "status_code"  => @response.status_code,
          "http_version" => @response.version,
          "timestamp"    => Helper.to_rfc3339(Time.utc),
        }
      end
    end

    Logging.register "json", self
  end
end
