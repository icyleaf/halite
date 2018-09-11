require "../../spec_helper"

describe HTTP::Params do
  describe "#encode" do
    it "should encode hash to url-encoded query" do
      HTTP::Params.encode({
        "name" => "Lizeth Gusikowski",
      }).should eq "name=Lizeth+Gusikowski"
    end

    it "should encode array in key to url-encoded query" do
      HTTP::Params.encode({
        "skill" => ["ruby", "crystal"],
      }).should eq "skill=ruby&skill=crystal"
    end

    it "should encode hash in key to url-encoded query" do
      HTTP::Params.encode({
        "company" => {
          "name" => "Keeling Inc",
        },
      }).should eq "company%5Bname%5D=Keeling+Inc"
    end

    it "should extract file name to uri-encoded query" do
      HTTP::Params.encode({
        "avatar" => File.open("halite-logo-small.png"),
      }).should eq "avatar=halite-logo-small.png"
    end

    it "should encode named tupled in key to url-encoded query" do
      HTTP::Params.encode({
        name:    "Lizeth Gusikowski",
        company: {
          name: "Keeling Inc",
        },
        skill: ["ruby", "crystal"],
      }).should eq "name=Lizeth+Gusikowski&company=%7Bname%3A+%22Keeling+Inc%22%7D&skill=ruby&skill=crystal"

      HTTP::Params.encode(
        name: "Lizeth Gusikowski",
        company: {
          name: "Keeling Inc",
        },
        skill: ["ruby", "crystal"]
      ).should eq "name=Lizeth+Gusikowski&company=%7Bname%3A+%22Keeling+Inc%22%7D&skill=ruby&skill=crystal"
    end
  end
end
