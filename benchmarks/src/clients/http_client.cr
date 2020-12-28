require "http/server"

module Client
  MEMBERS << {
    name: "built-in HTTP::Client",
    proc: ->(url : String) {
      HTTP::Client.get(url).body
    },
  }
end
