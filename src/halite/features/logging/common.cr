class Halite::Logging
  # Common logging format
  #
  # Instance variables to check `Halite::Logging::Abstract`
  #
  # ```
  # Halite.use("logging", logging: Halite::Logging::Common.new(skip_request_body: true))
  #   .get("http://httpbin.org/get")
  #
  # # Or
  # Halite.logging(format: "common", skip_request_body: true)
  #   .get("http://httpbin.org/get")
  #
  # # => 2018-08-31 16:56:12 +08:00 | request  | GET    | http://httpbin.org/get
  # # => 2018-08-31 16:56:13 +08:00 | response | 200    | http://httpbin.org/get | 1.08s | application/json
  # ```
  class Common < Abstract
    def request(request)
      message = String.build do |io|
        io << "> | request  | " << colorful_method(request.verb)
        io << "| " << request.uri
        unless request.body.empty? || @skip_request_body
          io << "\n" << request.body
        end
      end

      @logger.info { message }
      @request_time = Time.utc unless @skip_benchmark
    end

    def response(response)
      message = String.build do |io|
        content_type = response.content_type || "Unknown MIME"
        io << "< | response | " << colorful_status_code(response.status_code)
        io << "| " << response.uri
        if !@skip_benchmark && (request_time = @request_time)
          elapsed = Time.utc - request_time
          io << " | " << human_time(elapsed)
        end

        io << " | " << content_type
        unless response.body.empty? || binary_type?(content_type) || @skip_response_body
          io << "\n" << response.body
        end
      end

      @logger.info { message }
    end

    protected def colorful_method(method, is_request = true)
      fore, back = case method.upcase
                   when "GET"
                     [:white, :blue]
                   when "POST"
                     [:white, :cyan]
                   when "PUT"
                     [:white, :yellow]
                   when "DELETE"
                     [:white, :red]
                   when "PATCH"
                     [:white, :green]
                   when "HEAD"
                     [:white, :magenta]
                   else
                     [:dark_gray, :white]
                   end

      colorful((" %-7s" % method), fore, back)
    end

    protected def colorful_status_code(status_code : Int32)
      fore, back = case status_code
                   when 300..399
                     [:dark_gray, :white]
                   when 400..499
                     [:white, :yellow]
                   when 500..999
                     [:white, :red]
                   else
                     [:white, :green]
                   end

      colorful((" %-7s" % status_code), fore, back)
    end

    protected def colorful(message, fore, back)
      Colorize.enabled = !!(@colorize && (backend = @logger.backend.as?(Log::IOBackend)) && backend.io.tty?)

      message.colorize.fore(fore).back(back)
    end

    # return `true` if is binary types with MIME type
    #
    # MIME types list: https://developer.mozilla.org/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Complete_list_of_MIME_types
    private def binary_type?(content_type)
      binary_types = %w(image audio video)
      application_types = %w(pdf octet-stream ogg 3gpp ebook archive rar zip tar 7z word powerpoint excel flash font)

      binary_types.each do |name|
        return true if content_type.starts_with?(name)
      end

      application_types.each do |name|
        return true if content_type.starts_with?("application") && content_type.includes?(name)
      end

      false
    end

    Logging.register "common", self
  end
end
