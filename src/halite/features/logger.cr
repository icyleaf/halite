module Halite::Features
  class Laogger < Adapter
    def initialize(@name : String)
      pp @name
    end

    def request(request)
      request
    end

    def response(response)
      response
    end

    Halite::Features.register_feature("logger", self)
  end
end
