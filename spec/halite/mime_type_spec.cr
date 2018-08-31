require "../spec_helper"
require "yaml"

private class YAMLAdapter < Halite::MimeType::Adapter
  def decode(string)
    YAML.parse string
  end

  def encode(obj)
    obj.to_yaml
  end
end

describe Halite::MimeType do
  it "should register an adapter" do
    Halite::MimeType["yaml"]?.should be_nil
    Halite::MimeType["yml"]?.should be_nil

    Halite::MimeType.register YAMLAdapter.new, "application/x-yaml", "yaml", "yml"

    Halite::MimeType["yaml"].should be_a YAMLAdapter
    Halite::MimeType["yml"].should be_a YAMLAdapter
  end
end
