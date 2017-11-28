require "json"

module Halite::MimeTypes
  class JSON < Adapter
    def encode(obj)
      obj.to_json
    end

    def decode(str)
      ::JSON.parse str
    end
  end
end

Halite::MimeTypes.register_adapter "application/json", Halite::MimeTypes::JSON.new
Halite::MimeTypes.register_alias "application/json", "json"
