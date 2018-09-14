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

    it "accepts array to same key" do
      h = HTTP::Headers.encode(cookie: ["a=b", "c=d", "e=f"])
      h["Cookie"].should eq "a=b,c=d,e=f"
    end
  end

  describe "#to_flat_h" do
    flat_h = HTTP::Headers{"Accepts" => ["application/json", "text/html"], "Content-Type" => ["text/html"]}.to_flat_h
    flat_h["Accepts"].should eq(["application/json", "text/html"])
    flat_h["Content-Type"].should eq("text/html")
  end
end
