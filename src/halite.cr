require "./halite/*"
require "./halite/ext/*"

module Halite
  extend Chainable

  VERSION = "0.10.9"

  module Helper
    # Parses a `Time` into a [RFC 3339](https://tools.ietf.org/html/rfc3339) datetime format string
    # ([ISO 8601](http://xml.coverpages.org/ISO-FDIS-8601.pdf) profile).
    #
    # > Load Enviroment named "TZ" as high priority
    def self.to_rfc3339(time : Time, timezone = ENV["TZ"]?)
      location = timezone ? Time::Location.load(timezone.not_nil!) : Time::Location::UTC
      to_rfc3339(time, location)
    end

    def self.to_rfc3339(time : Time, location : Time::Location)
      Time::Format::RFC_3339.format(time.in(location))
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
