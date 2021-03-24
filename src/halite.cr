require "./halite/*"
require "./halite/ext/*"

module Halite
  extend Chainable

  VERSION = "0.12.0"

  module Helper
    # Parses a `Time` into a [RFC 3339](https://tools.ietf.org/html/rfc3339) datetime format string
    # ([ISO 8601](http://xml.coverpages.org/ISO-FDIS-8601.pdf) profile).
    #
    # > Load Enviroment named "TZ" as high priority
    def self.to_rfc3339(time : Time, *, timezone = ENV["TZ"]?, fraction_digits : Int = 0)
      Time::Format::RFC_3339.format(time.in(configure_location(timezone)), fraction_digits: fraction_digits)
    end

    # Parses a `Time` into a [RFC 3339](https://tools.ietf.org/html/rfc3339) datetime format string to `IO`
    # ([ISO 8601](http://xml.coverpages.org/ISO-FDIS-8601.pdf) profile).
    #
    # > Load Enviroment named "TZ" as high priority
    def self.to_rfc3339(time : Time, io : IO, *, timezone = ENV["TZ"]?, fraction_digits : Int = 0)
      Time::Format::RFC_3339.format(time.in(configure_location(timezone)), io, fraction_digits)
    end

    # :nodoc:
    private def self.configure_location(timezone = ENV["TZ"]?)
      timezone ? Time::Location.load(timezone.not_nil!) : Time::Location::UTC
    end
  end

  @@features = {} of String => Feature.class

  module FeatureRegister
    def register_feature(name : String, klass : Feature.class)
      @@features[name] = klass
    end

    def feature(name : String)
      @@features[name]
    end

    def feature?(name : String)
      @@features[name]?
    end

    def has_feature?(name)
      @@features.keys.includes?(name)
    end
  end

  extend FeatureRegister
end
