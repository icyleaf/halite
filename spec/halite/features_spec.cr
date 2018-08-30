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

describe Halite::Feature do
  it "should a empty feature" do
    feature = NullFeature.new
    feature.responds_to?(:request).should be_true
    feature.responds_to?(:response).should be_true
    feature.responds_to?(:intercept).should be_true
  end
end
