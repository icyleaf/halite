require "logger"
require "colorize"
require "file_utils"

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
      def self.new(file : String? = nil, filemode = "a",
                   skip_request_body = false, skip_response_body = false,
                   skip_benchmark = false, colorize = true)
        io = STDOUT
        if file
          file = File.expand_path(file)
          filepath = File.dirname(file)
          FileUtils.mkdir_p(filepath) unless Dir.exists?(filepath)

          io = File.open(file, filemode)
        end
        new(skip_request_body, skip_response_body, skip_benchmark, colorize, io)
      end

      setter logger : Logger
      getter skip_request_body : Bool
      getter skip_response_body : Bool
      getter skip_benchmark : Bool
      getter colorize : Bool

      @request_time : Time?

      def initialize(@skip_request_body = false, @skip_response_body = false,
                     @skip_benchmark = false, @colorize = true, @io : IO = STDOUT)
        @logger = Logger.new(@io, ::Logger::DEBUG, default_formatter, "halite")
        Colorize.enabled = @colorize
      end

      forward_missing_to @logger

      abstract def request(request)
      abstract def response(response)

      protected def default_formatter
        Logger::Formatter.new do |_, datetime, _, message, io|
          io << datetime.to_s << " " << message
        end
      end

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
