require "../../spec_helper"

private class SimpleLogger < Halite::Features::Logger::Abstract
  def request(request)
    @logger.info "request"
  end

  def response(response)
    @logger.info "response"
  end

  Halite::Features::Logger.register "simple", self
end

describe Halite::Features::Logger do
  it "should register an format" do
    Halite::Features::Logger["simple"].should eq(SimpleLogger)
    Halite::Features::Logger.availables.should eq ["common", "json", "simple"]
  end

  it "should use common as default logger" do
    logger = Halite::Features::Logger.new
    logger.writer.should be_a(Halite::Features::Logger::Common)
    logger.writer.skip_request_body.should be_false
    logger.writer.skip_response_body.should be_false
    logger.writer.skip_benchmark.should be_false
    logger.writer.colorize.should be_true
  end

  it "should use custom logger" do
    logger = Halite::Features::Logger.new(logger: SimpleLogger.new)
    logger.writer.should be_a(SimpleLogger)
    logger.writer.skip_request_body.should be_false
    logger.writer.skip_response_body.should be_false
    logger.writer.skip_benchmark.should be_false
    logger.writer.colorize.should be_true
  end
end
