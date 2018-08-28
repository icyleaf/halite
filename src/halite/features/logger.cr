require "logger"
require "colorize"

module Halite::Features

  # Logger feature
  class Logger < Feature
    def self.new(format : String = "common", logger : Logger::Abstract? = nil, **opts)
      return new(logger) if logger
      raise UnRegisterLoggerFormatError.new("Not avaiable logger format: #{format}") unless cls = Logger[format]?

      logger = cls.new(**opts)
      new(logger)
    end

    def initialize(@logger : Logger::Abstract = CommonLogger.new)
    end

    def request(request)
      @logger.request(request)
      request
    end

    def response(response)
      @logger.response(response)
      response
    end

    # Logger Abstract
    abstract class Abstract
      setter writer

      def self.new(filename : String? = nil, filemode : String? = nil,
                   skip_request_body = false, skip_response_body = false,
                   skip_benchmark = false, colorize = true)

        io = if filename && filemode
              File.open(filename.not_nil!, filemode.not_nil!)
            else
              STDOUT
            end
        new(skip_request_body, skip_response_body, skip_benchmark, colorize, io)
      end

      def initialize(@skip_request_body = false, @skip_response_body = false,
                     @skip_benchmark = false, @colorize = true, @io : IO = STDOUT)
        @writer = ::Logger.new(@io, ::Logger::DEBUG, default_formatter, "halite")
        Colorize.enabled = @colorize
      end

      forward_missing_to @writer

      abstract def request(request)
      abstract def response(response)

      def default_formatter
        ::Logger::Formatter.new do |_, datetime, _, message, io|
          io << datetime.to_s << " " << message
        end
      end
    end

    @@formats = {} of String => Abstract.class

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

    Halite::Features.register "logger", self
  end
end

require "./loggers/*"
