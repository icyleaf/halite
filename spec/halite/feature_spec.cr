require "../spec_helper"

describe Halite::Feature do
  it "should a empty feature" do
    feature = TestFeatures::Null.new
    feature.responds_to?(:request).should be_true
    feature.responds_to?(:response).should be_true
    feature.responds_to?(:intercept).should be_true
  end
end
