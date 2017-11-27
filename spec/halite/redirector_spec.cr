require "../spec_helper"

def request
  Halite::Request.new("get", "http://example.com/foo?bar=baz", HTTP::Headers{"Accept" => "text/html"})
end

def response(uri : URI, status_code = 200, headers = {} of String => String, body = "")
  Halite::Response.new(
    uri,
    HTTP::Client::Response.new(status_code: status_code, body: body, headers: HTTP::Headers.escape(headers))
  )
end

def redirector(request = request, response = response(request.uri))
  Halite::Redirector.new(request, response)
end

def simple_response(uri : URI, status_code = Int32, body = "", headers = {} of String => String|Array(String))
  Halite::Response.new(
    uri,
    HTTP::Client::Response.new(status_code: status_code, body: body, headers: HTTP::Headers.escape(headers))
  )
end

def redirect_response(status_code, location)
  simple_response URI.new("http://example.com"), status_code, "", {"Location" => location}
end

describe Halite::Redirector do
  describe "#strict" do
    it "should be true by default" do
      redirector.strict.should eq true
    end
  end

  describe "#max_hops" do
    it "should be 5 by default" do
      redirector.max_hops.should eq 5
    end
  end

  describe "#perform" do
    it "fails with TooManyRedirectsError if max hops reached" do
      req = Halite::Request.new "head", "http://example.com"
      res = -> (req : Halite::Request) { redirect_response(301, "#{req.uri}/1") }
      expect_raises Halite::TooManyRedirectsError do
        redirector(req, res.call(req)).perform do |prev_req|
          redirect_response(301, "#{prev_req.uri}/1")
        end
      end
    end

    it "fails with EndlessRedirectError if endless loop detected" do
      req = Halite::Request.new "head", "http://example.com"
      res = redirect_response(301, req.uri)

      expect_raises Halite::EndlessRedirectError do
        redirector(req, res).perform do |prev_req|
          res
        end
      end
    end

    it "fails with StateError if there were no Location header" do
      req = Halite::Request.new "head", "http://example.com"
      res = simple_response(req.uri, 301)

      expect_raises Halite::StateError do
        redirector(req, res).perform do |prev_req|
          res
        end
      end
    end
  end
end
