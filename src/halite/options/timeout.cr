module Halite
  class Options
    # Timeout struct
    struct Timeout
      getter connect : Float64?
      getter read : Float64?
      getter write : Float64?

      def initialize(connect : (Int32 | Float64 | Time::Span)? = nil,
                     read : (Int32 | Float64 | Time::Span)? = nil,
                     write : (Int32 | Float64 | Time::Span)? = nil)
        @connect = timeout_value(connect)
        @read = timeout_value(read)
        @write = timeout_value(write)
      end

      def connect=(connect : (Int32 | Float64 | Time::Span)?)
        @connect = timeout_value(connect)
      end

      def read=(read : (Int32 | Float64 | Time::Span)?)
        @read = timeout_value(read)
      end

      def write=(write : (Int32 | Float64 | Time::Span)?)
        @write = timeout_value(write)
      end

      private def timeout_value(value : (Int32 | Float64 | Time::Span)? = nil) : Float64?
        case value
        when Int32
          value.as(Int32).to_f
        when Float64
          value.as(Float64)
        when Time::Span
          value.as(Time::Span).total_seconds.to_f
        else
          nil
        end
      end
    end
  end

  # :nodoc:
  alias Timeout = Options::Timeout
end
