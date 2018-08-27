module Halite
  module Features
    @@adapters = {} of String => Features::Adapter.class

    def self.register_feature(name : String, feature : Features::Adapter.class)
      @@adapters[name] = feature
    end

    def self.[](name : String)
      @@adapters[name]
    end

    def self.[]?(name : String)
      @@adapters[name]?
    end

    def self.availables
      @@adapters.keys
    end

    abstract class Adapter
      def initialize(**options)
      end

      abstract def request(request : Request)
      abstract def response(response : Response)
    end
  end
end

require "./features/*"
