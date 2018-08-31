require "../../spec_helper"

describe Halite::Cache do
  it "should register a format" do
    Halite.has_feature?("cache").should be_true
    Halite.feature("cache").should eq(Halite::Cache)
  end
end
