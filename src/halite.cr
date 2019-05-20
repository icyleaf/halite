require "./halite/*"
require "./halite/ext/*"

module Halite
  extend Chainable

  VERSION = "0.10.0"

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
