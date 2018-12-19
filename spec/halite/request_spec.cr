require "../spec_helper"

private def request
  Halite::Request.new(
    "get",
    "http://example.com/foo/bar?q=halite#result",
    HTTP::Headers{"Accept" => "text/html"},
  )
end

describe Halite::Request do
  describe "#verb" do
    it "provides a #verb getter with upcase" do
      request.verb.should eq "GET"
    end
  end

  describe "#scheme" do
    it "provides a #scheme getter" do
      request.scheme.should eq "http"
    end
  end

  describe "#headers" do
    it "provides a given headers" do
      request.headers["Accept"].should eq "text/html"
    end

    it "could not set header with key and value" do
      request.headers["Via"] = "Halite"
      request.headers["Via"]?.should eq nil
    end
  end

  describe "#domain" do
    it "return `URI` with the scheme, user, password, port and host combined" do
      request.domain.to_s.should eq "http://example.com"
    end

    context "when subdomain and path are the same" do
      it "return `URI` with the scheme, user, password, port and host combined" do
        Halite::Request.new("get", "https://login.example.com/login").domain.to_s.should eq "https://login.example.com"
      end
    end
  end

  describe "#full_path" do
    it "provides a full_path" do
      request.full_path.should eq "/foo/bar?q=halite#result"
    end
  end

  describe "#body" do
    it "provides a body" do
      request.body.should eq ""
    end
  end

  describe "#redirect" do
    it "should return a new request" do
      request = Halite::Request.new("GET", "http://httpbin.com/redirect/3", headers: HTTP::Headers{"Host" => "httpbin.com"})
      new_request = request.redirect("http://httpbin.com/redirect/2")
      new_request.uri.to_s.should eq("http://httpbin.com/redirect/2")
      new_request.headers.has_key?("Host").should be_false
      new_request.verb.should eq("GET")
      request.uri.to_s.should eq("http://httpbin.com/redirect/3")
      request.verb.should eq("GET")
      request.headers.has_key?("Host").should be_true
    end

    it "should return a new request without Host" do
      request = Halite::Request.new("POST", "http://httpbin.com/redirect/3")
      new_request = request.redirect("http://httpbin.com/redirect/2", "GET")
      new_request.uri.to_s.should eq("http://httpbin.com/redirect/2")
      new_request.verb.should eq("GET")
      new_request.headers.has_key?("Host").should be_false
      request.uri.to_s.should eq("http://httpbin.com/redirect/3")
      request.verb.should eq("POST")
      request.headers.has_key?("Host").should be_false
    end
  end

  describe "raises" do
    it "should throws an exception with not allowed request method" do
      expect_raises Halite::UnsupportedMethodError, "Unknown method: TRACE" do
        Halite::Request.new("trace", "http://httpbin.org/get")
      end
    end

    it "should throws an exception without scheme part of URI" do
      expect_raises Halite::UnsupportedSchemeError, "Missing scheme: example.com" do
        Halite::Request.new("get", "example.com")
      end
    end

    it "should throws an exception with not allowed scheme part of URI" do
      expect_raises Halite::UnsupportedSchemeError, "Unknown scheme: ws" do
        Halite::Request.new("get", "ws://example.com")
      end
    end
  end
end
