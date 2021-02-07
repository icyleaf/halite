require "log"
require "colorize"
require "file_utils"

Log.setup("halite")

module Halite
  # Logging feature
  class Logging < Feature
    DEFAULT_LOGGER = Logging::Common.new

    getter writer : Logging::Abstract

    # return a new Cache instance
    #
    # Accepts argument:
    #
    # - **logging**: `Logging::Abstract`
    def initialize(**options)
      @writer = (logging = options[:logging]?) ? logging.as(Logging::Abstract) : DEFAULT_LOGGER
    end

    def request(request)
      @writer.request(request)
      request
    end

    def response(response)
      @writer.response(response)
      response
    end

    # Logging format Abstract
    abstract class Abstract
      def self.new(*, for : String = "halite", skip_request_body = false, skip_response_body = false,
                   skip_benchmark = false, colorize = true)
        new(skip_request_body, skip_response_body, skip_benchmark, colorize)
      end

      setter logger : Log
      getter skip_request_body : Bool
      getter skip_response_body : Bool
      getter skip_benchmark : Bool
      getter colorize : Bool

      @request_time : Time?

      def initialize(for : String = "halite", @skip_request_body = false, @skip_response_body = false,
                     @skip_benchmark = false, @colorize = true)
        @logger = Log.for(for)
        Colorize.enabled = @colorize
      end

      abstract def request(request)
      abstract def response(response)

      protected def human_time(elapsed : Time::Span)
        elapsed = elapsed.to_f
        case Math.log10(elapsed)
        when 0..Float64::MAX
          digits = elapsed
          suffix = "s"
        when -3..0
          digits = elapsed * 1000
          suffix = "ms"
        when -6..-3
          digits = elapsed * 1_000_000
          suffix = "µs"
        else
          digits = elapsed * 1_000_000_000
          suffix = "ns"
        end

        "#{digits.round(2).to_s}#{suffix}"
      end
    end

    @@formats = {} of String => Abstract.class

    # Logging format register
    module Register
      def register(name : String, format : Abstract.class)
        @@formats[name] = format
      end

      def [](name : String)
        @@formats[name]
      end

      def []?(name : String)
        @@formats[name]?
      end

      def availables
        @@formats.keys
      end
    end

    extend Register

    Halite.register_feature "logging", self
  end
end

require "./logging/*"
