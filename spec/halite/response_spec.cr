require "../spec_helper"

private URL         = "http://example.com"
private STATUS_CODE = 200
private HEADERS     = {"Content-Type" => "text/plain; charset=utf-8"}
private BODY        = "hello world"
private COOKIES     = "foo=bar; domain=example.com"

private def response(url = URL, status_code = STATUS_CODE, headers = HEADERS, body = BODY)
  Halite::Response.new(
    URI.parse(url),
    HTTP::Client::Response.new(status_code: status_code, body: body, headers: HTTP::Headers.encode(headers))
  )
end

private def empty_response
  Halite::Response.new(
    URI.parse(URL),
    HTTP::Client::Response.new(status_code: 404, body: "", headers: HTTP::Headers.new)
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

  describe "#content_type" do
    it "should return nil with empty headers" do
      empty_response.content_type.should be_nil
    end

    it "should return with string with contains headers" do
      response.content_type.should eq "text/plain"
    end
  end

  describe "#links" do
    # NOTE: more specs in `header_link_spec.cr`.
    it "should returns nil without Link Header" do
      response.links.should eq nil
    end

    it "should return a list of links" do
      r = response(headers: {"Link" => %Q{<https://api.github.com/user/repos?page=3&per_page=100>; rel="next"; title="Next Page", </>; rel="http://example.net/foo"}})
      r.links.should be_a Hash(String, Halite::HeaderLink)
      if links = r.links
        links.has_key?("next").should be_true
        links["next"].rel.should eq "next"
        links["next"].target.should eq "https://api.github.com/user/repos?page=3&per_page=100"
        links["next"].params.size.should eq 1
        links["next"].params["title"].should eq "Next Page"
        links["next"].to_s.should eq "https://api.github.com/user/repos?page=3&per_page=100"

        links.has_key?("/").should be_false
        links["http://example.net/foo"].rel.should eq "http://example.net/foo"
        links["http://example.net/foo"].target.should eq "http://example.net/foo"
        links["http://example.net/foo"].params.size.should eq 0
        links["http://example.net/foo"].to_s.should eq "http://example.net/foo"
      end
    end
  end

  describe "#raise_for_status" do
    it "should returns nil when status_code not range in (400..599)" do
      response.raise_for_status.should be_nil
    end

    (400..499).each do |code|
      it "throws an Halite::ClientError if status_code is #{code}" do
        expect_raises Halite::ClientError do
          response(status_code: code).raise_for_status
        end
      end
    end

    (500..599).each do |code|
      it "throws an Halite::ServerError if status_code is #{code}" do
        expect_raises Halite::ServerError do
          response(status_code: code).raise_for_status
        end
      end
    end
  end

  describe "#parse" do
    context "with known content type" do
      it "returns parsed body" do
        r = response(headers: {"Content-Type" => "application/json;charset=utf-8"}, body: %q{{"foo":"bar"}})
        r.parse.should eq({"foo" => "bar"})
      end
    end

    context "with empty content type" do
      it "raises Halite::UnRegisterMimeTypeError" do
        r = response(headers: {"Content-Type" => ""})
        expect_raises Halite::Error do
          r.parse
        end
      end
    end

    context "without content type" do
      it "raises Halite::UnRegisterMimeTypeError" do
        r = response(headers: {"Etag" => "123123123"})
        expect_raises Halite::Error do
          r.parse
        end
      end
    end

    context "with unknown content type" do
      it "raises Halite::UnRegisterMimeTypeError" do
        r = response(headers: {"Content-Type" => "application/html"})
        expect_raises Halite::UnRegisterMimeTypeError do
          r.parse
        end
      end
    end

    context "with explicitly given mime type" do
      it "ignores mime_type of response" do
        r = response(headers: {"Content-Type" => "application/html; charset=utf-8"}, body: %q{{"foo":"bar"}})
        r.parse("application/json").should eq({"foo" => "bar"})
      end

      it "supports MIME type aliases" do
        r = response(headers: {"Content-Type" => "application/html; charset=utf-8"}, body: %q{{"foo":"bar"}})
        r.parse("json").should eq({"foo" => "bar"})
      end
    end
  end

  describe "#inspect" do
    it "returns human-friendly response representation" do
      response.inspect.should eq %q{#<Halite::Response HTTP/1.1 200 OK {"Content-Type" => "text/plain; charset=utf-8"}>}
    end
  end
end
