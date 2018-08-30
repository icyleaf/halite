module Halite
  module Features
    @@features = {} of String => Feature.class

    def self.register(name : String, klass : Feature.class)
      @@features[name] = klass
    end

    def self.[](name : String)
      @@features[name]
    end

    def self.[]?(name : String)
      @@features[name]?
    end

    def self.availables
      @@features.keys
    end
  end

  abstract class Feature
    def initialize(**options)
    end

    # Cooks with request
    def request(request : Request) : Request
      request
    end

    # Cooking with response
    def response(response : Response) : Response
      response
    end

    # Intercept and cooking request and response
    def intercept(chain : Interceptor::Chain) : Interceptor::Chain
      chain
    end
  end

  # Interceptor for feature
  module Interceptor
    # Interceptor chain
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

      @performed_response : Response?

      def initialize(@request : Request, @response : Response?, @options : Options, &block : -> Response)
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
