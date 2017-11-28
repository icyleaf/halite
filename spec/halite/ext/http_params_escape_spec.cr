require "../../spec_helper"

describe HTTP::Params do
  describe "#escape" do
    it "should escape hash to url-encoded query" do
      HTTP::Params.escape({
        "name"    => "Lizeth Gusikowski"
      }).should eq "name=Lizeth+Gusikowski"
    end

    it "should escape array in key to url-encoded query" do
      HTTP::Params.escape({
        "skill"   => ["ruby", "crystal"],
      }).should eq "skill=ruby&skill=crystal"
    end

    it "should escape hash in key to url-encoded query" do
      HTTP::Params.escape({
        "company" => {
          "name" => "Keeling Inc",
        },
      }).should eq "company=%7B%22name%22+%3D%3E+%22Keeling+Inc%22%7D"
    end

    it "should extract file name to uri-encoded query" do
      HTTP::Params.escape({
        "avatar" => File.open("halite-logo-small.png")
      }).should eq "avatar=halite-logo-small.png"
    end
  end
end
