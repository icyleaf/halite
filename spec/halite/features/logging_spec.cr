require "../../spec_helper"

describe Halite::Logging do
  it "should register a format" do
    Halite::Logging["simple"].should eq(SimpleLogger)
    Halite::Logging.availables.should eq ["common", "json", "simple"]
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
    logger = Halite::Logging.new(logger: SimpleLogger.new)
    logger.writer.should be_a(SimpleLogger)
    logger.writer.skip_request_body.should be_false
    logger.writer.skip_response_body.should be_false
    logger.writer.skip_benchmark.should be_false
    logger.writer.colorize.should be_true
  end
end
