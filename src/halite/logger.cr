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
      @logger.level = ::Logger::DEBUG
      @logger.progname = "halite"
      @logger.formatter = default_formatter
    end

    abstract def request(request : Halite::Request) : String
    abstract def response(response : Halite::Response) : String

    def default_formatter
      ::Logger::Formatter.new do |severity, datetime, progname, message, io|
        io << progname
        io << " | " << datetime.to_s("%F %T")
        io << " " << message
      end
    end
  end
end

require "./loggers/*"
