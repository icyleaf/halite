require "../spec_helper"

describe Halite::Features do
  describe "register" do
    it "should use a registered feature" do
      Halite::Features["null"]?.should be_nil
      Halite::Features.register "null", TestFeatures::Null
      Halite::Features.availables.includes?("null").should be_true
      Halite::Features["null"].should eq(TestFeatures::Null)
    end
  end
end

describe Halite::Feature do
  it "should a empty feature" do
    feature = TestFeatures::Null.new
    feature.responds_to?(:request).should be_true
    feature.responds_to?(:response).should be_true
    feature.responds_to?(:intercept).should be_true
  end
end
