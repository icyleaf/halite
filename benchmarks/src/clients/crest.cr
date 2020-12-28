require "crest"

module Client
  MEMBERS << {
    name: "crest",
    proc: ->(url : String) {
      Crest.get(url).body
    },
  }
end
