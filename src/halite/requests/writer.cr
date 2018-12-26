module Halite
  class Request
    class Writer
      # CRLF is the universal HTTP delimiter
      CRLF = "\r\n"

      # Chunked data termintaor.
      ZERO = "0"

      # Chunked transfer encoding
      CHUNKED = "chunked"

      # End of a chunked transfer
      CHUNKED_END = "#{ZERO}#{CRLF}#{CRLF}"

      def self.new(socket : IO, body : String | IO | Enumerable | Nil, headers : HTTP::Headers, headline : String)
        new(socket, Body.new(body), headers, headline)
      end

      def initialize(@socket : IO, @body : Request::Body,
                     @headers : HTTP::Headers, headline : String)
        @request_headers = [headline]
      end

      # Stream the request to a socket
      def stream
        add_headers
        send_request
        @socket.flush
      end

      # Adds headers to the request header from the headers array
      def add_headers
        @headers.each do |name, value|
          @request_headers << "#{name}: #{value.join(", ")}"
        end

        unless has_content_length? || chunked?
          @request_headers << "Content-Length: #{@body.size}"
        end
      end

      # Writes HTTP request data into the socket.
      def send_request
        join_headers
        each_chunks
        closure_chunked
      end

      # Joins the headers specified in the request into a correctly formatted
      # http request header string
      def join_headers
        # join the headers array with crlfs, stick two on the end because
        # that ends the request header
        @socket << @request_headers.join(CRLF) << CRLF * 2
      end

      def each_chunks
        @body.each {|chunk| write chunk}
      end

      def closure_chunked
        if chunked?
          @socket << CHUNKED_END
        else
          @socket << CRLF
        end
      end

      # Returns true if the request has content length.
      def has_content_length?
        @headers.has_key?("Content-Length")
      end

      # Returns true if the request should be sent in chunked encoding.
      def chunked?
        @headers["Transfer-Encoding"]? == CHUNKED
      end

      private def write(chunk : String | Slice(UInt8))
        if chunked?
          write_chunk(chunk)
        else
          @socket << chunk
        end
      end

      private def write_chunk(chunk : String)
        chunk.size.to_s(16, @socket)
        @socket << CRLF << chunk << CRLF
      end

      private def write_chunk(chunk : Slice(UInt8))
        chunk.size.to_s(16, @socket)
        @socket << CRLF
        @socket.write(chunk)
        @socket << CRLF
      end
    end
  end
end
