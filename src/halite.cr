require "./halite/version"
require "./halite/ext/*"
require "./halite/chainable"
# require "./halite/utils"

require "./halite/form_data"
require "./halite/options"
require "./halite/client"

module Halite
  extend Chainable
end
