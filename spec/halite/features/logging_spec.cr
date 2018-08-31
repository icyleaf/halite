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

  it "should use common as default logger" do
    logger = Halite::Logging.new
    logger.writer.should be_a(Halite::Logging::Common)
    logger.writer.skip_request_body.should be_false
    logger.writer.skip_response_body.should be_false
    logger.writer.skip_benchmark.should be_false
    logger.writer.colorize.should be_true
  end

  it "should use custom logger" do
    logger = Halite::Logging.new(logger: NulleLogger.new)
    logger.writer.should be_a(NulleLogger)
    logger.writer.skip_request_body.should be_false
    logger.writer.skip_response_body.should be_false
    logger.writer.skip_benchmark.should be_false
    logger.writer.colorize.should be_true
  end
end
