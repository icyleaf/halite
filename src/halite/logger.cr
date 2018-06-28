require "logger"
require "file_utils"

module Halite
  module Logger
    @@adapters = {} of String => Halite::Logger::Adapter

    def self.register_adapter(name : String, adapter : Halite::Logger::Adapter)
      @@adapters[name] = adapter
    end

    def self.[](name : String)
      @@adapters[name]
    end

    def self.[]?(name : String)
      @@adapters[name]?
    end

    def self.adapter_names
      @@adapters.keys
    end

    def self.clear
      @@adapters.clear
    end

    abstract class Adapter
      def self.new(filename : String, mode = "a")
        file_path = File.dirname(filename)
        if file_path != "." && !Dir.exists?(file_path)
          FileUtils.mkdir_p(file_path)
        end

        new(File.open(filename, mode))
      end

      setter writer

      def initialize(@io : IO = STDOUT)
        @writer = ::Logger.new(@io, ::Logger::DEBUG, default_formatter, "halite")
      end

      forward_missing_to @writer

      abstract def request(request : Halite::Request)
      abstract def response(response : Halite::Response)

      def default_formatter
        ::Logger::Formatter.new do |severity, datetime, progname, message, io|
          io << datetime.to_s << " " << message
        end
      end
    end
  end
end

require "./loggers/*"
