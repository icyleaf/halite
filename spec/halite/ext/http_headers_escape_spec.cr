require "../../spec_helper"

describe HTTP::Headers do
  describe "#escape" do
    it "should accepts Hash(String, _)" do
      HTTP::Headers.escape({
        "foo"    => "bar",
        "number" => 1,
        "bool"   => false,
        "array"  => ["1", "2", "false"],
      }).size.should eq 4
    end

    it "should accepts NamedTuple" do
      HTTP::Headers.escape({
        foo:    "bar",
        number: 1,
        bool:   false,
        array:  ["1", "2", "false"],
      }).size.should eq 4
    end

    it "should accepts tuples as params" do
      HTTP::Headers.escape(foo: "bar", name: ["foo", "bar"]).size.should eq 2
    end

    it "should return as HTTP::Params" do
      HTTP::Headers.escape({} of String => String).class.should eq HTTP::Headers
    end
  end

  it "accepts array to same key" do
    h = HTTP::Headers.escape(cookie: ["a=b", "c=d", "e=f"])
    h["Cookie"].should eq "a=b,c=d,e=f"
  end
end
