require "crest"

module Servers
  MEMBERS << {
    "name" => "crest",
    "proc" => -> (url : String) {
      Crest.get(url).body
    }
  }
end
