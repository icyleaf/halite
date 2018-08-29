module Halite
  module Features
    @@featurs = {} of String => Feature.class

    def self.register(name : String, feature : Feature.class)
      @@featurs[name] = feature
    end

    def self.[](name : String)
      @@featurs[name]
    end

    def self.[]?(name : String)
      @@featurs[name]?
    end

    def self.availables
      @@featurs.keys
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

    # Interceptor
    #
    # Intercept and cooking request and response
    def intercept(chain : Interceptor::Chain) : Interceptor::Chain
      chain
    end
  end

  module Interceptor
    class Chain
      enum Result
        Next
        Return
      end

      property request
      getter response
      getter result

      def initialize(@request : Request, @response : Response?, @options : Options, &block : -> Response)
        @result = Result::Next
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

      def perform
        @perform_request_block.call
      end
    end
  end
end

require "./features/*"
