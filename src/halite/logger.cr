require "logger"
require "colorize"

module Halite
  abstract class Logger
    def self.new(filename : String)
      new(File.open(filename, "w"))
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
