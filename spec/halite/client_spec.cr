require "../spec_helper"

describe Halite::Client do
  describe "#initialize" do
    it "should initial with nothing" do
      client = Halite::Client.new
      client.should be_a(Halite::Client)
    end

    it "should initial with Hash client" do
      client = Halite::Client.new({
        "headers" => {
          user_agent: "Spec"
        }
      })

      client.should be_a(Halite::Client)
      client.options.headers["User-Agent"].should eq("Spec")
    end

    it "should initial with NamedTuple client" do
      client = Halite::Client.new({
        headers: {
          private_token: "token",
        },
        connect_timeout: 1.minutes,
      })

      client.should be_a(Halite::Client)
      client.options.headers.should be_a(HTTP::Headers)
      client.options.headers["Private-Token"].should eq("token")
      client.options.timeout.connect.should eq(60)
    end
  end
end
