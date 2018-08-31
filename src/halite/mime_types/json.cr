require "json"

module Halite::MimeType
  class JSON < Adapter
    def encode(obj)
      obj.to_json
    end

    def decode(str)
      ::JSON.parse str
    end
  end
end

Halite::MimeType.register Halite::MimeType::JSON.new, "application/json", "json"
