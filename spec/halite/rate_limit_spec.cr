require "../spec_helper"

# private def parse_it(raw : String, uri : URI? = nil)
#   Halite::HeaderLinkParser.parse(raw, uri)
# end

describe Halite::RateLimit do
  describe "#parse" do
    it "should works with full arguments" do
      headers = HTTP::Headers{
        "X-RateLimit-Limit"     => "5000",
        "X-RateLimit-Remaining" => "4991",
        "X-RateLimit-Reset"     => "1613727325",
      }
      subject = Halite::RateLimit.parse(headers)
      subject.should be_a Halite::RateLimit
      subject.not_nil!.limit.should eq 5000
      subject.not_nil!.remaining.should eq 4991
      subject.not_nil!.reset.should eq 1613727325
    end

    it "should works with optional arguments" do
      headers = HTTP::Headers{
        "X-RateLimit-Limit" => "5000",
      }
      subject = Halite::RateLimit.parse(headers)
      subject.should be_a Halite::RateLimit
      subject.not_nil!.limit.should eq 5000
      subject.not_nil!.remaining.should be_nil
      subject.not_nil!.reset.should be_nil
    end

    it "should not works without any headers" do
      headers = HTTP::Headers.new
      subject = Halite::RateLimit.parse(headers)
      subject.should be_nil
    end
  end

  describe "#new" do
    it "should works with full arguments" do
      subject = Halite::RateLimit.new(5000, 4991, 1613727325)
      subject.limit.should eq 5000
      subject.remaining.should eq 4991
      subject.reset.should eq 1613727325
    end

    it "should works with optional arguments" do
      subject = Halite::RateLimit.new(nil, nil, nil)
      subject.limit.should be_nil
      subject.remaining.should be_nil
      subject.reset.should be_nil
    end
  end
end
