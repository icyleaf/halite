require "./support/**"
require "./clients/**"

module Client
  MEMBERS = [] of NamedTuple(name: String, proc: Proc(String, String))
end

url = run_server

sleep 1

Benchmark.tach(10_000) do |x|
  Client::MEMBERS.each do |client|
    x.report(client["name"]) do
      client["proc"].call(url)
    end
  end
end
