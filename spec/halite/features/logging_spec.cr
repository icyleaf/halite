require "../../spec_helper"

private class NulleLogger < Halite::Logging::Abstract
  def request(request)
  end

  def response(response)
  end
end

describe Halite::Logging do
  describe "#register" do
    it "should register a format" do
      Halite::Logging.register "null", NulleLogger
      Halite::Logging.availables.includes?("null").should be_true
      Halite::Logging["null"].should eq(NulleLogger)
    end
  end

  describe "#initilize" do
    it "should use common as default logging" do
      logging = Halite::Logging.new
      logging.writer.should be_a(Halite::Logging::Common)
      logging.writer.skip_request_body.should be_false
      logging.writer.skip_response_body.should be_false
      logging.writer.skip_benchmark.should be_false
      logging.writer.colorize.should be_true
    end

    it "should use custom logging" do
      logging = Halite::Logging.new(logging: NulleLogger.new)
      logging.writer.should be_a(NulleLogger)
      logging.writer.skip_request_body.should be_false
      logging.writer.skip_response_body.should be_false
      logging.writer.skip_benchmark.should be_false
      logging.writer.colorize.should be_true
    end

    it "should use File IO" do
      with_tempfile("halite-features-logging") do |file|
        uri = URI.parse("https://httpbin.org/get")
        writer = Halite::Logging::Common.new(file: file)
        logging = Halite::Logging.new(logging: writer)
        logging.writer.should be_a(Halite::Logging::Common)
        logging.request(Halite::Request.new("get", uri))
        logging.response(Halite::Response.new(
          uri,
          HTTP::Client::Response.new(status_code: 200, body: "foobar", headers: HTTP::Headers.encode({"Content-Type" => "text/plain; charset=utf-8"}))
        ))

        logs = File.read_lines(file).join("\n")
        logs.should contain("request")
        logs.should contain("response")
      end
    end
  end
end
