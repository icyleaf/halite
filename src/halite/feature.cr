module Halite
  abstract class Feature
    def initialize(**options)
    end

    # Cooks with request
    def request(request : Halite::Request) : Halite::Request
      request
    end

    # Cooking with response
    def response(response : Halite::Response) : Halite::Response
      response
    end

    # Intercept and cooking request and response
    def intercept(chain : Halite::Feature::Chain) : Halite::Feature::Chain
      chain
    end

    # Feature chain
    #
    # Chain has two result:
    #
    # next: perform and run next interceptor
    # return: perform and return
    class Chain
      enum Result
        Next
        Return
      end

      property request
      getter response
      getter result

      @performed_response : Halite::Response?

      def initialize(@request : Halite::Request, @response : Halite::Response?, @options : Halite::Options, &block : -> Halite::Response)
        @result = Result::Next
        @performed_response = nil
        @perform_request_block = block
      end

      def next(response)
        @result = Result::Next
        @response = response

        self
      end

      def return(response)
        @result = Result::Return
        @response = response

        self
      end

      def performed?
        !@performed_response.nil?
      end

      def perform
        @performed_response ||= @perform_request_block.call
        @performed_response.not_nil!
      end
    end
  end
end

require "./features/*"
