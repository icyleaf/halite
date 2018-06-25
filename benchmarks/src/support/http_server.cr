require "http/server"

def run_server
  port = 12381
  server = HTTP::Server.new do |context|
    context.response.content_type = "text/plain"
    text = "x" * 10000
    context.response.print text
  end

  spawn do
    server.listen(port)
  end

  "http://localhost:#{port}"
end
