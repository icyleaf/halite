require "cossack"

module Servers
  MEMBERS << {
    "name" => "cossack",
    "proc" => -> (url : String) {
      Cossack.get(url).body
    }
  }
end
