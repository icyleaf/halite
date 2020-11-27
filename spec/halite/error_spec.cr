require "../spec_helper"

describe Halite::Exception do
  describe "#APIError" do
    it "should initial without arguments" do
      error = Halite::APIError.new
      error.message.should be_nil
      error.status_code.should be_nil
      error.status_message.not_nil!.should eq "unknown error"
    end

    it "should initial with message only" do
      message = "foobar"

      error = Halite::APIError.new(message)
      error.message.not_nil!.should eq message
      error.status_code.should be_nil
      error.status_message.not_nil!.should eq "foobar error"
    end

    it "should initial with message and status_code" do
      message = "foobar"
      status_code = 400

      error = Halite::APIError.new(message, status_code)
      error.message.not_nil!.should eq message
      error.status_code.not_nil!.should eq status_code
      error.status_message.not_nil!.should eq "bad request error"
    end

    it "should initial with full arguments" do
      message = "foobar"
      status_code = 400
      uri = URI.parse("https://www.example.com/get/foobar")

      error = Halite::APIError.new(message, status_code, uri)
      error.message.not_nil!.should eq message
      error.status_code.not_nil!.should eq status_code
      error.uri.not_nil!.should eq uri
      error.status_message.not_nil!.should eq "bad request error with url: #{uri}"
    end

    it "should initial without message" do
      status_code = 400
      uri = URI.parse("https://www.example.com/get/foobar")

      error = Halite::APIError.new(nil, status_code, uri)
      error.message.not_nil!.should eq "#{status_code} bad request error with url: #{uri}"
      error.status_code.not_nil!.should eq status_code
      error.uri.not_nil!.should eq uri
      error.status_message.not_nil!.should eq "bad request error with url: #{uri}"
    end
  end
end
