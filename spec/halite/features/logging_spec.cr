require "../../spec_helper"

private class NulleLogger < Halite::Logging::Abstract
  def request(request)
  end

  def response(response)
  end
end

describe Halite::Logging do
  it "should register a format" do
    Halite::Logging.register "null", NulleLogger
    Halite::Logging.availables.includes?("null").should be_true
    Halite::Logging["null"].should eq(NulleLogger)
  end

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
end
