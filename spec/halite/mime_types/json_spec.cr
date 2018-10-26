require "../../spec_helper"

private class Foo
end

describe Halite::MimeType::JSON do
  describe "#encode" do
    it "should work with to_json class" do
      json = Halite::MimeType::JSON.new
      json.encode({name: "foo"}).should eq(%Q{{"name":"foo"}})
    end
  end

  describe "#decode" do
    it "should work with json string" do
      json = Halite::MimeType::JSON.new
      json.decode(%Q{{"name": "foo"}}).should be_a(JSON::Any)
      json.decode(%Q{{"name": "foo"}}).should eq({"name" => "foo"})
    end
  end
end
