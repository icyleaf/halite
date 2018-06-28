module Halite
  module MimeTypes
    @@adapters = {} of String => Adapter

    def self.register_adapter(name : String, adapter : Adapter)
      @@adapters[name] = adapter
    end

    @@aliases = {} of String => String

    def self.register_alias(name : String, shortcut : String)
      @@aliases[shortcut] = name
    end

    def self.[](name : String)
      @@adapters[normalize name]
    end

    def self.[]?(name : String)
      @@adapters[normalize name]?
    end

    private def self.normalize(name : String)
      @@aliases.fetch name, name
    end

    abstract class Adapter
      abstract def encode(obj)
      abstract def decode(string)
    end
  end
end

require "./mime_types/*"
