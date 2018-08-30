require "../spec_helper"

private class NullFeature < Halite::Feature
end

describe Halite::Features do
  describe "register" do
    it "should use a registered feature" do
      Halite::Features["null"]?.should be_nil
      Halite::Features.register "null", NullFeature
      Halite::Features.availables.includes?("null").should be_true
      Halite::Features["null"].should eq(NullFeature)
    end
  end
end
