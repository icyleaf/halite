require "json"

module Halite::Logger
  class JSON < Adapter
    @created_at : Time? = nil
    @request : Request? = nil
    @response : Response? = nil

    def request(request)
      @created_at = Time.now
      @request = Request.new(request)
    end

    def response(response)
      @response = Response.new(response)
      @writer.info raw
    end

    def default_formatter
      ::Logger::Formatter.new do |severity, datetime, progname, message, io|
        io << message
      end
    end

    private def raw
      {
        "created_at" => Time::Format::RFC_3339.format(@created_at.not_nil!, 0),
        "entry"      => {
          "request"  => @request.not_nil!.to_h,
          "response" => @response.not_nil!.to_h,
        },
      }.to_pretty_json
    end

    struct Request
      def initialize(@request : Halite::Request)
      end

      def to_h
        {
          "body"      => @request.body,
          "headers"   => @request.headers.to_h,
          "method"    => @request.verb,
          "url"       => @request.uri.to_s,
          "timestamp" => Time::Format::RFC_3339.format(Time.now, 0),
        }
      end
    end

    struct Response
      def initialize(@response : Halite::Response)
      end

      def to_h
        {
          "body"         => @response.body,
          "header"       => @response.headers.to_h,
          "status_code"  => @response.status_code,
          "http_version" => @response.version,
          "timestamp"    => Time::Format::RFC_3339.format(Time.now, 0),
        }
      end
    end
  end
end

Halite::Logger.register_adapter "json", Halite::Logger::JSON.new
