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

    def initialize(@io : IO = STDOUT)
      @logger = ::Logger.new(@io, ::Logger::DEBUG, default_formatter, "halite")
    end

    forward_missing_to @logger

    abstract def request(request : Halite::Request)
    abstract def response(response : Halite::Response)

    # return Halite logger formatter
    def default_formatter
      ::Logger::Formatter.new do |severity, datetime, progname, message, io|
        io << datetime.to_s << " " << message
      end
    end
  end
end

require "./loggers/*"
