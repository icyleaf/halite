module Halite
  class CommonLogger < Logger
    def request(request)
      message = String.build do |io|
        io << "|" << colorful_method(request.verb)
        io << "| " << request.uri
        io << " | " << request.body unless request.body.empty?
      end.to_s

      @logger.info message
    end

    def response(response)
      message = String.build do |io|
        mime_type = response.mime_type.nil? ? "Unkown MIME" : response.mime_type.not_nil!

        io << "|" << colorful_status_code(response.status_code)
        io << "| " << response.uri
        io << " | " << mime_type

        unless response.body.empty?
          body = if binary_type?(mime_type)
            "[binary file]"
          else
            response.body
          end

          io << " | " << body
        end
      end.to_s

      @logger.debug message
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
      Colorize.enabled = !@io.is_a?(File)
      message.colorize.fore(fore).back(back)
    end

    # return if is binary types with MIME type
    #
    # MIME types list: https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Complete_list_of_MIME_types
    private def binary_type?(mime_type)
      binary_types = %w(image audio video)
      application_types = %w(pdf octet-stream ogg 3gpp ebook archive rar zip tar 7z word powerpoint excel flash font)

      binary_types.each do |name|
        return true if mime_type.starts_with?(name)
      end

      application_types.each do |name|
        return true if mime_type.starts_with?("application") && mime_type.includes?(name)
      end

      false
    end
  end
end
