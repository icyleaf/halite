require "./support/**"
require "./servers/**"

module Servers
  MEMBERS = [] of Hash(String, String | Proc(String, String))
end

url = run_server

sleep 1

Benchmark.tach(1_000) do |x|
  Servers::MEMBERS.each do |server|
    name = server["name"].as(String)
    block = server["proc"].as(Proc)

    x.report(name) do
      block.call(url)
    end
  end
end
