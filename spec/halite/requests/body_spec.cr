require "../../spec_helper"

private def chunks(body)
  Array(String).new.tap do |obj|
    body.each do |chunk|
      obj << chunk.dup.to_s
    end
  end
end

describe Halite::Request::Body do
  describe "#initialize" do
    context "when body is nil" do
      it "should works" do
        body = Halite::Request::Body.new(nil)
        body.source.should be_nil
      end
    end

    context "when body is a string" do
      it "should works" do
        body = Halite::Request::Body.new("request body")
        body.source.should eq "request body"
      end
    end

    context "when body is an IO" do
      it "should works" do
        source = IO::Memory.new("request body")
        body = Halite::Request::Body.new(source)
        body.source.should eq source
      end
    end

    context "when body is an Enumerable(String)" do
      it "should works" do
        body = Halite::Request::Body.new(%w(foo bar))
        body.source.should eq(["foo", "bar"])
      end
    end
  end

  describe "#size" do
    context "when body is nil" do
      it "returns size" do
        body = Halite::Request::Body.new(nil)
        body.size.should eq 0
      end
    end

    context "when body is a string" do
      it "returns size" do
        body = Halite::Request::Body.new("hello 中国！")
        body.size.should eq 15
      end
    end

    context "when body is an IO with size" do
      it "returns size" do
        source = IO::Memory.new("request body")
        body = Halite::Request::Body.new(source)
        body.size.should eq 12
      end
    end

    context "when body is an IO without size" do
      it "raises a RequestError" do
        source = IO::Sized.new(IO::Memory.new("request body"), read_size: 3)
        body = Halite::Request::Body.new(source)
        expect_raises Halite::Exception::RequestError, "IO object must respond to #size" do
          body.size
        end
      end
    end

    context "when body is an Enumerable" do
      it "raises a RequestError" do
        body = Halite::Request::Body.new(%w(foo bar))
        expect_raises Halite::Exception::RequestError, "Cannot determine size of body" do
          body.size
        end
      end
    end
  end

  describe "#each" do
    context "when body is nil" do
      it "yields nothing" do
        body = Halite::Request::Body.new(nil)
        chunks(body).should eq(Array(String).new)
      end
    end

    context "when body is a string" do
      it "yields the string" do
        body = Halite::Request::Body.new("request body")
        chunks(body).should eq(["request body"])
      end
    end

    context "when body is a non-Enumerable IO" do
      it "yields chunks of content" do
        source = IO::Memory.new("a" * 2 * 1024 + "b" * 5 * 1024)
        body = Halite::Request::Body.new(source)
        raw = chunks(body).reduce("") { |str, i| str += i }
        raw.should eq("a" * 2 * 1024 + "b" * 5 * 1024)
      end
    end

    context "when body is an Enumerable(String)" do
      it "should works" do
        body = Halite::Request::Body.new(%w(foo bar))
        body.source.should eq(["foo", "bar"])
      end
    end
  end

  # it "should accepts Nil type value" do
  #   body = Halite::Request::Body.new(nil)
  #   body.size.should eq 0
  #   chunks(body).should eq Array(String).new
  # end

  # it "should accepts a String type value" do
  #   raw = "user=王雪峰"
  #   body = Halite::Request::Body.new(raw)
  #   chunks(body).should eq([raw])
  # end

  # it "should accepts a non-Enumerable IO type value" do
  #   raw = IO::Memory.new("你好")
  #   body = Halite::Request::Body.new(raw)
  #   body.size.should eq raw.size
  #   chunks(body).should eq([raw.to_s])
  # end

  # it "should accepts a IO type value" do
  #   raw = IO::Memory.new("你好")
  #   body = Halite::Request::Body.new(raw)
  #   body.size.should eq raw.size

  #   chunks(body).should eq([raw.to_s])
  # end
end
