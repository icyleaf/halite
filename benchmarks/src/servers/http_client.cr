require "http/server"

module Servers
  MEMBERS << {
    "name" => "built-in http client",
    "proc" => -> (url : String) {
      HTTP::Client.get(url).body
    }
  }
end
