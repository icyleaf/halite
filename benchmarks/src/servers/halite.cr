require "halite"

module Servers
  MEMBERS << {
    "name" => "halite",
    "proc" => -> (url : String) {
      Halite::Client.new.request("get", url).body
    }
  }

  MEMBERS << {
    "name" => "halite (persistent)",
    "proc" => -> (url : String) {
      Halite.get(url).body
    }
  }
end
