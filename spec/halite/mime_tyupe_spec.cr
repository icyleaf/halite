require "../spec_helper"
require "yaml"

private class YAMLAdapter < Halite::MimeTypes::Adapter
  def decode(string)
    YAML.parse string
  end

  def encode(obj)
    obj.to_yaml
  end
end

describe Halite::MimeTypes do
  it "should register an adapter" do
    Halite::MimeTypes["yaml"]?.should be_nil
    Halite::MimeTypes["yml"]?.should be_nil

    Halite::MimeTypes.register_adapter "application/x-yaml", YAMLAdapter.new
    Halite::MimeTypes.register_alias "application/x-yaml", "yaml"
    Halite::MimeTypes.register_alias "application/x-yaml", "yml"

    Halite::MimeTypes["yaml"].should be_a YAMLAdapter
    Halite::MimeTypes["yml"].should be_a YAMLAdapter
  end

  it "should overwrite exists adapter" do
    Halite::MimeTypes.register_adapter "application/json", YAMLAdapter.new
    Halite::MimeTypes.register_alias "application/json", "json"

    Halite::MimeTypes["json"].should be_a YAMLAdapter
    Halite::MimeTypes["json"].should_not be_a Halite::MimeTypes::JSON
  end
end
