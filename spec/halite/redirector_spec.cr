require "../spec_helper"

private def request
  Halite::Request.new("head", "http://example.com/foo?bar=baz")
end

def response(uri : URI, status_code = 200, headers = {} of String => String, body = "")
  Halite::Response.new(
    uri,
    HTTP::Client::Response.new(status_code: status_code, body: body, headers: HTTP::Headers.encode(headers))
  )
end

def redirector(request, response, strict = true, max_hops = 5)
  Halite::Redirector.new(request, response, max_hops, strict)
end

def simple_response(status_code = Int32, body = "", headers = {} of String => String | Array(String))
  Halite::Response.new(
    URI.new("http://example.com"),
    HTTP::Client::Response.new(status_code: status_code, body: body, headers: HTTP::Headers.encode(headers))
  )
end

def redirect_response(status_code, location)
  simple_response status_code, "", {"Location" => location}
end

describe Halite::Redirector do
  describe "#strict" do
    it "should be true by default" do
      redirector(request, response(request.uri)).strict.should eq true
    end
  end

  describe "#max_hops" do
    it "should be 5 by default" do
      redirector(request, response(request.uri)).max_hops.should eq 5
    end
  end

  describe "#perform" do
    it "fails with TooManyRedirectsError if max hops reached" do
      res = ->(req : Halite::Request) { redirect_response(301, "#{req.uri}/1") }
      expect_raises Halite::TooManyRedirectsError do
        redirector(request, res.call(request)).perform do |prev_req|
          redirect_response(301, "#{prev_req.uri}/1")
        end
      end
    end

    it "fails with EndlessRedirectError if endless loop detected" do
      res = redirect_response 301, request.uri
      expect_raises Halite::EndlessRedirectError do
        redirector(request, res).perform do |_|
          res
        end
      end
    end

    it "fails with StateError if there were no Location header" do
      res = simple_response 301
      expect_raises Halite::StateError do
        redirector(request, res).perform do |_|
          res
        end
      end
    end

    it "returns first non-redirect response" do
      hops = [
        redirect_response(301, "http://example.com/1"),
        redirect_response(301, "http://example.com/2"),
        redirect_response(301, "http://example.com/3"),
        simple_response(200, "foo"),
        redirect_response(301, "http://example.com/4"),
        simple_response(200, "bar"),
      ]

      res = redirector(request, hops.shift).perform { hops.shift }
      res.to_s.should eq "foo"
    end

    context "following 300/301/302 redirect" do
      context "with strict mode" do
        it "it follows with original verb if it's safe" do
          req = Halite::Request.new "get", "http://example.com/foo?bar=baz"
          res = redirect_response 300, "http://example.com/1"

          redirector(req, res, true).perform do |prev_req|
            prev_req.verb.should eq "GET"
            simple_response 200
          end
        end

        it "raises StateError if original request was PUT" do
          req = Halite::Request.new "put", "http://example.com/foo?bar=baz"
          res = redirect_response 300, "http://example.com/1"
          expect_raises Halite::StateError do
            redirector(req, res, true).perform { |_| simple_response 200 }
          end
        end

        it "raises StateError if original request was POST" do
          req = Halite::Request.new "post", "http://example.com/foo?bar=baz"
          res = redirect_response 301, "http://example.com/1"
          expect_raises Halite::StateError do
            redirector(req, res, true).perform { |_| simple_response 200 }
          end
        end

        it "raises StateError if original request was DELETE" do
          req = Halite::Request.new "delete", "http://example.com/foo?bar=baz"
          res = redirect_response 302, "http://example.com/1"
          expect_raises Halite::StateError do
            redirector(req, res, true).perform { |_| simple_response 200 }
          end
        end
      end

      context "without strict mode" do
        it "it follows with original verb if it's safe" do
          req = Halite::Request.new "get", "http://example.com/foo?bar=baz"
          res = redirect_response 300, "http://example.com/1"

          redirector(req, res, false).perform do |prev_req|
            prev_req.verb.should eq "GET"
            simple_response 200
          end
        end

        it "raises StateError if original request was PUT" do
          req = Halite::Request.new "put", "http://example.com/foo?bar=baz"
          res = redirect_response 300, "http://example.com/1"
          redirector(req, res, false).perform do |prev_req|
            prev_req.verb.should eq "GET"
            simple_response 200
          end
        end

        it "raises StateError if original request was POST" do
          req = Halite::Request.new "post", "http://example.com/foo?bar=baz"
          res = redirect_response 301, "http://example.com/1"
          redirector(req, res, false).perform do |prev_req|
            prev_req.verb.should eq "GET"
            simple_response 200
          end
        end

        it "raises StateError if original request was DELETE" do
          req = Halite::Request.new "delete", "http://example.com/foo?bar=baz"
          res = redirect_response 302, "http://example.com/1"
          redirector(req, res, false).perform do |prev_req|
            prev_req.verb.should eq "GET"
            simple_response 200
          end
        end
      end
    end

    context "following 303 redirect" do
      it "follows with HEAD if original request was HEAD" do
        req = Halite::Request.new "head", "http://example.com/foo?bar=baz"
        res = redirect_response 303, "http://example.com/1"

        redirector(req, res).perform do |prev_req|
          prev_req.verb.should eq "HEAD"
          simple_response 200
        end
      end

      it "follows with GET if original request was GET" do
        req = Halite::Request.new "get", "http://example.com/foo?bar=baz"
        res = redirect_response 303, "http://example.com/1"

        redirector(req, res).perform do |prev_req|
          prev_req.verb.should eq "GET"
          simple_response 200
        end
      end

      it "follows with GET if original request was neither GET nor HEAD" do
        req = Halite::Request.new "post", "http://example.com/foo?bar=baz"
        res = redirect_response 303, "http://example.com/1"

        redirector(req, res).perform do |prev_req|
          prev_req.verb.should eq "GET"
          simple_response 200
        end
      end
    end

    context "following 307 redirect" do
      it "follows with original request's verb" do
        req = Halite::Request.new "post", "http://example.com/foo?bar=baz"
        res = redirect_response 307, "http://example.com/1"

        redirector(req, res).perform do |prev_req|
          prev_req.verb.should eq "POST"
          simple_response 200
        end
      end
    end

    context "following 308 redirect" do
      it "follows with original request's verb" do
        req = Halite::Request.new "post", "http://example.com/foo?bar=baz"
        res = redirect_response 308, "http://example.com/1"

        redirector(req, res).perform do |prev_req|
          prev_req.verb.should eq "POST"
          simple_response 200
        end
      end
    end
  end
end
