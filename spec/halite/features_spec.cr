require "../spec_helper"

private class NullFeature < Halite::Feature
end

describe Halite::Features do
  it "should register a feature" do
    Halite::Features["null"]?.should be_nil
    Halite::Features.register "null", NullFeature
    Halite::Features["null"].should eq(NullFeature)
  end
end
