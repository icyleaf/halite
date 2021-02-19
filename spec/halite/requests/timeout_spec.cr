require "../../spec_helper"

describe Halite::Timeout do
  describe "#initialize" do
    it "should set with Int32" do
      timeout = Halite::Timeout.new(1, 2, 3)
      timeout.connect.should eq(1.0)
      timeout.read.should eq(2)
      timeout.write.should eq(3)
    end

    it "should set with Float64" do
      timeout = Halite::Timeout.new(1.2, 3.4, 5.6)
      timeout.connect.should eq(1.2)
      timeout.read.should eq(3.4)
      timeout.write.should eq(5.6)
    end

    it "should set with Time::Span" do
      timeout = Halite::Timeout.new(1.seconds, 1.minutes, 1.hour)
      timeout.connect.should eq(1.0)
      timeout.read.should eq(60.0)
      timeout.write.should eq(3600.0)
    end

    it "should set different format" do
      timeout = Halite::Timeout.new(1, 1.minutes, 10.0)
      timeout.connect.should eq(1.0)
      timeout.read.should eq(60.0)
      timeout.write.should eq(10.0)

      timeout = Halite::Timeout.new(1.2, 1, Time::Span.new(seconds: 30, nanoseconds: 0))
      timeout.connect.should eq(1.2)
      timeout.read.should eq(1.0)
      timeout.write.should eq(30.0)
    end

    it "should set one argument" do
      timeout = Halite::Timeout.new(1)
      timeout.connect.should eq(1.0)
      timeout.read.should be_nil
      timeout.write.should be_nil

      timeout = Halite::Timeout.new(connect: 2)
      timeout.connect.should eq(2.0)
      timeout.read.should be_nil
      timeout.write.should be_nil

      timeout = Halite::Timeout.new(read: 3)
      timeout.connect.should be_nil
      timeout.read.should eq(3.0)

      timeout = Halite::Timeout.new(write: 3)
      timeout.connect.should be_nil
      timeout.read.should be_nil
      timeout.write.should eq(3.0)
    end
  end

  describe "setter" do
    it "should set with Int32" do
      timeout = Halite::Timeout.new
      timeout.connect = 3
      timeout.connect.should eq(3.0)

      timeout.read = 12
      timeout.read.should eq(12.0)

      timeout.write = 1
      timeout.write.should eq(1.0)
    end

    it "should set with Float64" do
      timeout = Halite::Timeout.new(1, 2)
      timeout.connect = 3.0
      timeout.connect.should eq(3.0)

      timeout.read = 12.0
      timeout.read.should eq(12.0)

      timeout.write = 1.0
      timeout.write.should eq(1.0)
    end

    it "should set with Time::Span" do
      timeout = Halite::Timeout.new(1, 2)
      timeout.connect = 3.seconds
      timeout.connect.should eq(3.0)

      timeout.read = 1.minutes
      timeout.read.should eq(60.0)

      timeout.write = 1.hour
      timeout.write.should eq(3600.0)
    end
  end
end
