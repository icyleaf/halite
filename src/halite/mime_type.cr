module Halite
  module MimeType
    @@adapters = {} of String => MimeType::Adapter
    @@aliases = {} of String => String

    def self.register(adapter : MimeType::Adapter, name : String, *shortcuts)
      @@adapters[name] = adapter
      shortcuts.each do |shortcut|
        next unless shortcut.is_a?(String)
        @@aliases[shortcut] = name
      end unless shortcuts.empty?
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
