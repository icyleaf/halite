require "../../spec_helper"

describe Halite::Proxy do
  describe ".environment_proxies" do
    it "should return empty if nothing proxy in environment" do
      Halite::Proxy.environment_proxies.empty?.should be_true
    end

    it "should returns proxies case-insensitive from environment" do
      temp_envorinment({"http_proxy" => "http://localhost:8080", "HTTPS_PROXY" => "http://localhost:8081"}) do
        proxies = Halite::Proxy.environment_proxies
        proxies.size.should eq 2
        proxies["http"].should eq "http://localhost:8080"
        proxies["https"].should eq "http://localhost:8081"
      end
    end
  end

  describe "#initialize" do
    it "should accepts host and port" do
      proxy = Halite::Proxy.new("localhost", 8080)
      proxy.host.should eq "localhost"
      proxy.port.should eq 8080
      proxy.username.should be_nil
      proxy.password.should be_nil
      proxy.using_authenticated?.should be_false
      proxy.skip_verify?.should be_false
    end

    it "should accepts proxy with authorization" do
      proxy = Halite::Proxy.new("127.0.0.1", 8080, "foo", "123456")
      proxy.host.should eq "127.0.0.1"
      proxy.port.should eq 8080
      proxy.username.should eq "foo"
      proxy.password.should eq "123456"
      proxy.using_authenticated?.should be_true
      proxy.authorization_header.should eq HTTP::Headers{"Proxy-Authentication" => "Basic Zm9vOjEyMzQ1Ng=="}
      proxy.skip_verify?.should be_false
    end

    it "should accepts a url" do
      proxy = Halite::Proxy.new(url: "https://127.0.0.1:8080")
      proxy.host.should eq "127.0.0.1"
      proxy.port.should eq 8080
      proxy.username.should be_nil
      proxy.password.should be_nil
      proxy.using_authenticated?.should be_false
      proxy.skip_verify?.should be_false
    end

    it "should accepts a verify" do
      proxy = Halite::Proxy.new(url: "http://127.0.0.1:8080", verify: false)
      proxy.host.should eq "127.0.0.1"
      proxy.port.should eq 8080
      proxy.username.should be_nil
      proxy.password.should be_nil
      proxy.using_authenticated?.should be_false
      proxy.skip_verify?.should be_true
    end
  end
end
