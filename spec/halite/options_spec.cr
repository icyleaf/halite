require "../spec_helper"

describe Halite::Options do
  describe "#initialize" do
    it "should initial with nothing" do
      subject = Halite::Options.new
      subject.should be_a(Halite::Options)
    end

    it "should initial with options" do
      subject = Halite::Options.new({
        "headers" => {
          "private_token" => "token",
        },
      })

      subject.should be_a(Halite::Options)
      subject.headers.should be_a(HTTP::Headers)
      subject.headers["Private-Token"].should eq("token")
    end
  end
end
