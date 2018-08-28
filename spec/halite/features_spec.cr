require "../spec_helper"

private class SimpleFeature < Halite::Feature
  def request(request); request; end
  def response(response); response; end
end

describe Halite::Features do
  it "should register an adapter" do
    Halite::Features["yaml"]?.should be_nil
    Halite::Features["yml"]?.should be_nil

    Halite::Features.register_adapter "application/x-yaml", YAMLAdapter.new

    Halite::Features["yaml"].should be_a YAMLAdapter
  end

  it "should overwrite exists adapter" do
    Halite::Features.register_adapter "application/json", YAMLAdapter.new

    Halite::Features["json"].should be_a YAMLAdapter

    Halite::Features.register_adapter "application/json", Halite::Features::JSON.new
  end
end
