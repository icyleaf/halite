require "../../spec_helper"

private class Foo
end

describe Halite::MimeTypes::JSON do
  describe "#encode" do
    it "shoulds works with to_json class" do
      json = Halite::MimeTypes::JSON.new
      json.encode({name: "foo"}).should eq(%Q{{"name":"foo"}})
    end
  end

  describe "#decode" do
    it "shoulds works with json string" do
      json = Halite::MimeTypes::JSON.new
      json.decode(%Q{{"name": "foo"}}).should be_a(JSON::Any)
      json.decode(%Q{{"name": "foo"}}).should eq({"name" => "foo"})
    end
  end
end
