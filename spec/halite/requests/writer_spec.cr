require "../../spec_helper"

private def headline
  "GET /halite HTTP/1.1"
end

private def writer(io, body, headers = HTTP::Headers.new, headline : String = headline)
  Halite::Request::Writer.new(io, body, headers, headline)
end

describe Halite::Request::Writer do
  describe "#stream" do
    context "when multiple headers are set" do
      it "separates headers with carriage return and line feed" do
        io = IO::Memory.new
        writer(io, "", headers: HTTP::Headers{"Host" => "example.com"}).stream
        io.to_s.should eq([
          "#{headline}",
          "Host: example.com",
          "Content-Length: 0",
          "\r\n"
        ].join("\r\n"))
      end
    end

    context "when body is empty" do
      it "doesn't write anything to the socket and sets Content-Length" do
        io = IO::Memory.new
        writer(io, nil).stream

        io.to_s.should eq([
          "#{headline}",
          "Content-Length: 0",
          "\r\n"
        ].join("\r\n"))
      end
    end

    context "when body is nonempty" do
      it "separates headers with carriage return and line feed" do
        io = IO::Memory.new
        writer(io, "body").stream
        io.to_s.should eq([
          "#{headline}",
          "Content-Length: 4\r\n",
          "body"
        ].join("\r\n"))
      end
    end

    context "when Content-Length header is set" do
      it "keeps the given value" do
        io = IO::Memory.new
        writer(io, "body", HTTP::Headers{"Content-Length" => "12"}).stream
        io.to_s.should eq([
          "#{headline}",
          "Content-Length: 12\r\n",
          "body"
        ].join("\r\n"))
      end
    end

    context "when Transfer-Encoding is chunked" do
      context "let body is Enumerable" do
        it "writes encoded content and omits Content-Length" do
          io = IO::Memory.new
          writer(io, ["hey", "halite"], HTTP::Headers{"Transfer-Encoding" => "chunked"}).stream
          io.to_s.should eq([
            "#{headline}",
            "Transfer-Encoding: chunked\r\n",
            "3",
            "hey",
            "6",
            "halite",
            "0",
            "\r\n"
          ].join("\r\n"))
        end
      end

      context "let body is IO" do
        it "writes encoded content and omits Content-Length" do
          io = IO::Memory.new
          writer(io, IO::Memory.new("a" * 4 * 1024 + "b" * 4 * 1024), HTTP::Headers{"Transfer-Encoding" => "chunked"}).stream
          io.to_s.should eq([
            "#{headline}",
            "Transfer-Encoding: chunked\r\n",
            "1000",
            "a" * 4 * 1024,
            "1000",
            "b" * 4 * 1024,
            "0",
            "\r\n"
          ].join("\r\n"))
        end
      end
    end
  end
end
