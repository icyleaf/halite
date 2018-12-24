module Halite
  class Request
    class Body
      getter source

      def initialize(@source : String | IO | Enumerable(String) | Nil)
      end

      def size
        if @source.is_a?(String)
          @source.as(String).bytesize
        elsif @source.responds_to?(:read)
          if (source = @source).responds_to?(:size)
            source.size
          else
            raise RequestError.new("IO object must respond to #size")
          end
        elsif @source.nil?
          0
        else
          raise RequestError.new("Cannot determine size of body: #{@source}")
        end
      end

      def each(&block : (String | Slice(UInt8)) ->)
        case @source
        when String
          yield @source.as(String)
        when IO
          IO.copy(@source.as(IO), ProcIO.new(block: block))
          if (source = @source).responds_to?(:rewind)
            source.rewind
          end
        when Enumerable
          @source.as(Enumerable).each(&block)
        end
      end

      # This class provides a "writable IO" wrapper around a proc object, with
      # #write simply calling the proc, which we can pass in as the
      # "destination IO" in IO.copy.
      struct ProcIO
        def initialize(@block : (String | Slice(UInt8)) ->)
        end

        def write(data)
          @block.call(data)
          data.bytesize
        end
      end
    end
  end
end
