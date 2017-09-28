require "./spec_helper"
require "./support/mock_server"

# Start mock server
server = MockServer.new
spawn do
  server.listen
end

# Wait server a moment
sleep 1

describe Halite do
  # describe ".get" do
  #   context "loading a simple uri" do
  #     it "should easy to request" do
  #       response = Halite.get server.endpoint
  #       response.to_s.should match(/<!doctype html>/)
  #     end
  #   end

  #   context "with query string parameters" do
  #     it "should easy to request" do
  #       response = Halite.get "#{server.endpoint}/params", params: {foo: "bar"}
  #       response.to_s.should eq("Params!")
  #     end
  #   end

  #   context "with query string parameters in the URI and opts hash" do
  #     it "includes both" do
  #       response = Halite.get "#{server.endpoint}/multiple-params?foo=bar", params: {baz: "quux"}
  #       response.to_s.should eq("More Params!")
  #     end
  #   end

    context "with headers" do
      it "is easy" do
        response = Halite.accept("application/json").get server.endpoint
        response.to_s.should match(/json/)
      end
    end

  #   # context "loading binary data" do
  #   #   it "is encoded as bytes" do
  #   #     response = Halite.get "#{server.endpoint}/bytes"
  #   #     # response.to_s.encoding.should eq(Encoding::BINARY)
  #   #   end
  #   # end

  #   context "with a large request body" do
  #     [16_000, 16_500, 17_000, 34_000, 68_000].each do |size|
  #       [0, rand(0..100), rand(100..1000)].each do |fuzzer|
  #         context "with a #{size} body and #{fuzzer} of fuzzing" do
  #           it "returns a large body" do
  #             characters = ("A".."Z").to_a
  #             form = Hash(String, String).new.tap { |obj| (size + fuzzer).times { |i| obj[i.to_s] = characters[i % characters.size] } }
  #             response = Halite.post "#{server.endpoint}/echo-body", form: form
  #             response_body = HTTP::Params.escape(form)

  #             response.to_s.should eq(response_body)
  #             response.content_length.should eq(response_body.bytesize)
  #           end
  #         end
  #       end
  #     end
  #   end
  # end

  # describe ".post" do
  #   context "loading a simple form data" do
  #     it "should easy to request" do
  #       response = Halite.post "#{server.endpoint}/form", form: {example: "testing-form"}
  #       response.to_s.should eq("passed :)")
  #     end
  #   end
  # end

  describe ".follow" do
    context "with redirects" do
      it "should easy for 301 with full uri" do
        response = Halite.follow.get("#{server.endpoint}/redirect-301")
        response.to_s.should match(/<!doctype html>/)
      end

      it "should easy for 301 with relative path" do
        response = Halite.follow.get("#{server.endpoint}/redirect-301", params: {"relative_path" => true})
        response.to_s.should match(/<!doctype html>/)
      end

      it "should easy for 302" do
        response = Halite.follow.get("#{server.endpoint}/redirect-302")
        response.to_s.should match(/<!doctype html>/)
      end
    end
  end

  context ".head" do
    it "should easy to request" do
      response = Halite.head server.endpoint
      response.status_code.should eq(200)
      response.content_type.should match(/html/)
    end
  end
end

# Clean up
server.close
