require "logger"
require "file_utils"

module Halite
  abstract class Logger
    def self.new(filename : String, mode = "a")
      file_path = File.dirname(filename)
      if file_path != "." && !Dir.exists?(file_path)
        FileUtils.mkdir_p(file_path)
      end

      new(File.open(filename, mode))
    end

    forward_missing_to @logger

    def initialize(@io : IO = STDOUT)
      @logger = ::Logger.new(@io)
      @logger.progname = "halite"
      @logger.level = ::Logger::DEBUG
      @logger.formatter = default_formatter
    end

    abstract def request(request : Halite::Request)
    abstract def response(response : Halite::Response)

    # return Halite logger formatter
    def default_formatter
      ::Logger::Formatter.new do |severity, datetime, progname, message, io|
        if category = Fiber.current.logger_context["category"]?
          io << category << " | "
        end

        io << datetime.to_s << " " << message
      end
    end
  end
end

class Fiber
  property logger_context : Hash(String, String)?

  def logger_context
    @logger_context ||= {} of String => String
    @logger_context.not_nil!
  end
end

require "./loggers/*"
