require "../spec_helper"

# private class SimpleLogger < Halite::Logger::Adapter
#   def request(request)
#     @writer.info "request"
#   end

#   def response(response)
#     @writer.info "response"
#   end
# end

# describe Halite::Logger do
#   it "should register an adapter" do
#     Halite::Logger.register_adapter "simple", SimpleLogger.new
#     Halite::Logger["simple"].should be_a SimpleLogger

#     Halite::Logger.availables.should eq ["common", "json", "simple"]
#   end

#   it "should overwrite exists adapter" do
#     Halite::Logger.register_adapter "common", SimpleLogger.new

#     Halite::Logger["common"].should be_a SimpleLogger
#     Halite::Logger["common"].should_not be_a Halite::Logger::Common

#     # Restore back for other specs
#     Halite::Logger.register_adapter "common", Halite::Logger::Common.new
#   end
# end
