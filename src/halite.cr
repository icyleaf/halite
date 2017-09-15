require "./halite/version"
require "./halite/ext/*"
require "./halite/error"
require "./halite/chainable"
require "./halite/form_data"
require "./halite/options"
require "./halite/client"

module Halite
  extend Chainable
end
