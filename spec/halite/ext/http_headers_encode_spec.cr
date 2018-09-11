require "../../spec_helper"

describe HTTP::Headers do
  describe "#encode" do
    it "should accepts Hash(String, _)" do
      HTTP::Headers.encode({
        "foo"    => "bar",
        "number" => 1,
        "bool"   => false,
        "array"  => ["1", "2", "false"],
      }).size.should eq 4
    end

    it "should accepts NamedTuple" do
      HTTP::Headers.encode({
        foo:    "bar",
        number: 1,
        bool:   false,
        array:  ["1", "2", "false"],
      }).size.should eq 4
    end

    it "should accepts tuples as params" do
      HTTP::Headers.encode(foo: "bar", name: ["foo", "bar"]).size.should eq 2
    end

    it "should return as HTTP::Params" do
      HTTP::Headers.encode({} of String => String).class.should eq HTTP::Headers
    end
  end

  it "accepts array to same key" do
    h = HTTP::Headers.encode(cookie: ["a=b", "c=d", "e=f"])
    h["Cookie"].should eq "a=b,c=d,e=f"
  end
end
