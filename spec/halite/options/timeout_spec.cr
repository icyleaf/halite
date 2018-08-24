require "../../spec_helper"

describe Halite::Timeout do
  describe "#initlize" do
    it "shoulds sets with Int32" do
      timeout = Halite::Timeout.new(1, 2)
      timeout.connect.should eq(1.0)
      timeout.read.should eq(2)
    end

    it "shoulds sets with Float64" do
      timeout = Halite::Timeout.new(1.2, 3.4)
      timeout.connect.should eq(1.2)
      timeout.read.should eq(3.4)
    end

    it "shoulds sets with Time::Span" do
      timeout = Halite::Timeout.new(1.seconds, 1.minutes)
      timeout.connect.should eq(1.0)
      timeout.read.should eq(60.0)
    end

    it "shoulds sets different format" do
      timeout = Halite::Timeout.new(1, 1.minutes)
      timeout.connect.should eq(1.0)
      timeout.read.should eq(60.0)

      timeout = Halite::Timeout.new(1.2, 1)
      timeout.connect.should eq(1.2)
      timeout.read.should eq(1.0)
    end

    it "shoulds sets one argument" do
      timeout = Halite::Timeout.new(1)
      timeout.connect.should eq(1.0)
      timeout.read.should be_nil

      timeout = Halite::Timeout.new(connect: 2)
      timeout.connect.should eq(2.0)
      timeout.read.should be_nil

      timeout = Halite::Timeout.new(read: 3)
      timeout.connect.should be_nil
      timeout.read.should eq(3.0)
    end
  end

  describe "setter" do
    it "should sets with Int32" do
      timeout = Halite::Timeout.new
      timeout.connect = 3
      timeout.connect.should eq(3.0)

      timeout.read = 12
      timeout.read.should eq(12.0)
    end

    it "should sets with Float64" do
      timeout = Halite::Timeout.new(1, 2)
      timeout.connect = 3.0
      timeout.connect.should eq(3.0)

      timeout.read = 12.0
      timeout.read.should eq(12.0)
    end

    it "should sets with Time::Span" do
      timeout = Halite::Timeout.new(1, 2)
      timeout.connect = 3.seconds
      timeout.connect.should eq(3.0)

      timeout.read = 1.minutes
      timeout.read.should eq(60.0)
    end
  end
end