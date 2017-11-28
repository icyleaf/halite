require "../spec_helper"

def request
  Halite::Request.new("get", "http://example.com/foo?bar=baz", HTTP::Headers{"Accept" => "text/html"})
end

describe Halite::Request do
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

  it "provides a #scheme getter" do
    request.scheme.should eq "http"
  end

  it "provides a #verb getter" do
    request.verb.should eq "GET"
  end

  it "sets given headers" do
    request.headers["Accept"].should eq "text/html"
  end
end
