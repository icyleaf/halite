require "http"

module Halite
  module FormData
    extend Utils

    def self.create(data : Hash(String, Options::Type) = {} of String => Options::Type)
      if multipart?(data)
        io = IO::Memory.new
        builder = HTTP::FormData::Builder.new(io)
        data.each do |k, v|
          case v
          when File
            builder.file(k, v.as(IO), HTTP::FormData::FileMetadata.new(filename: v.path))
          when Array
            v.each do |e|
              builder.field(k, e.to_s)
            end
          else
            builder.field(k, v.to_s)
          end
        end
        builder.finish

        [io.to_s, builder.content_type]
      else
        content_type = "application/x-www-form-urlencoded"
        body = encode_www_form(data)

        [body, content_type]
      end
    end

    private def self.multipart?(data : Hash(String, Options::Type))
      data.any? do |_, v|
        next true if v.is_a?(File)
      end
    end
  end
end
