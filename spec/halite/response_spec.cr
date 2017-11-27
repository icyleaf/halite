require "../spec_helper"

URL         = "http://example.com"
STATUS_CODE = 200
HEADERS     = {"Content-Type" => "text/plain"}
BODY        = "hello world"
COOKIES     = "foo=bar; domain=example.com"

def response(url = URL, status_code = STATUS_CODE, headers = HEADERS, body = BODY)
  Halite::Response.new(
    URI.parse(url),
    HTTP::Client::Response.new(status_code: status_code, body: body, headers: HTTP::Headers.escape(headers))
  )
end

describe Halite::Response do
  describe "to_a" do
    it "returns a Rack-like array" do
      response.to_a.should eq([STATUS_CODE, HEADERS, BODY])
    end
  end

  describe "#content_length" do
    it "should without Content-Length header" do
      response.content_length.should be_nil
    end

    it "should return content length with number" do
      r = response(headers: {"Content-Length" => "5"})
      r.content_length.should eq 5
    end

    it "should return invalid Content-Length" do
      r = response(headers: {"Content-Length" => "foo"})
      r.content_length.should be_nil
    end
  end

  describe "#cookies" do
    it "should HTTP::Cookies class" do
      r = response(headers: {"Set-Cookie" => COOKIES})
      r.cookies.class.should eq HTTP::Cookies
      r.cookies["foo"].class.should eq HTTP::Cookie
      r.cookies["foo"].value.should eq "bar"
      r.cookies["foo"].domain.should eq "example.com"
    end
  end

  describe "#inspect" do
    it "returns human-friendly response representation" do
      response.inspect.should eq %q{#<Halite::Response HTTP/1.1 200 OK {"Content-Type" => "text/plain"}>}
    end
  end
end
