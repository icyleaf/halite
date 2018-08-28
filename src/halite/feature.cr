module Halite
  module Features
    @@featurs = {} of String => Features::Feature.class

    def self.register(name : String, feature : Features::Feature.class)
      @@featurs[name] = feature
    end

    def self.[](name : String)
      @@featurs[name]
    end

    def self.[]?(name : String)
      @@featurs[name]?
    end

    def self.availables
      @@featurs.keys
    end

    abstract class Feature
      def initialize(**options)
      end

      abstract def request(request : Request) : Request
      abstract def response(response : Response) : Response
    end
  end
end

require "./features/*"
