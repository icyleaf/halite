module Halite
  class Options
    struct Follow
      # No follow by default
      DEFAULT_HOPS = 0

      # A maximum of 5 subsequent redirects
      MAX_HOPS = 5

      # Redirector hops policy
      STRICT = true

      property hops : Int32
      property strict : Bool

      def initialize(hops : Int32? = nil, strict : Bool? = nil)
        @hops = hops || DEFAULT_HOPS
        @strict = strict.nil? ? STRICT : strict
      end

      def strict?
        @strict == true
      end

      def updated?
        @hops != DEFAULT_HOPS || @strict != STRICT
      end
    end
  end

  # :nodoc:
  alias Follow = Options::Follow
end
