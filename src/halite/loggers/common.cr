require "colorize"

module Halite::Logger
  class Common < Adapter
    def request(request)
      message = String.build do |io|
        io << "| request  |" << colorful_method(request.verb)
        io << "| " << request.uri
        io << "\n" << request.body unless request.body.empty?
      end

      @writer.info message
    end

    def response(response)
      message = String.build do |io|
        content_type = response.content_type.nil? ? "Unkown MIME" : response.content_type.not_nil!

        io << "| response |" << colorful_status_code(response.status_code)
        io << "| " << response.uri
        io << " | " << content_type
        io << "\n" << response.body unless response.body.empty? || binary_type?(content_type)
      end

      @writer.debug message
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
  end
end

Halite::Logger.register_adapter "common", Halite::Logger::Common.new
