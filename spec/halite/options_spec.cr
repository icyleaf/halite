require "../spec_helper"

describe Halite::Options do
  describe "#initialize" do
    it "should initial with nothing" do
      subject = Halite::Options.new
      subject.should be_a(Halite::Options)
    end

    it "should initial with Hash arguments" do
      subject = Halite::Options.new({
        "headers" => {
          "private_token" => "token",
        },
        "connect_timeout" => 3.2
      })

      subject.should be_a(Halite::Options)
      subject.headers.should be_a(HTTP::Headers)
      subject.headers["Private-Token"].should eq("token")
      subject.timeout.connect.should eq(3.2)
    end

    it "should initial with NamedTuple arguments" do
      subject = Halite::Options.new({
        headers: {
          private_token: "token",
        },
        connect_timeout: 1.minutes
      })

      subject.should be_a(Halite::Options)
      subject.headers.should be_a(HTTP::Headers)
      subject.headers["Private-Token"].should eq("token")
      subject.timeout.connect.should eq(60)
    end
  end
end