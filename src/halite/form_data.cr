require "http/formdata"
require "http/multipart"

module Halite
  # Utility-belt to build form data request bodies.
  #
  # Provides support for `application/x-www-form-urlencoded` and
  # `multipart/form-data` types.
  #
  # ```
  # form = FormData.create({
  #   "name"   => "Lizeth Gusikowski",
  #   "skill"  => ["ruby", "crystal"],
  #   "avatar" => File.open("avatar.png"), # => "image binary data"
  # })
  #
  # form.body    # => "----------------------------_ytTht-0D5oif0cAGXSPjPSN\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nLizeth Gusikowski\r\n----------------------------_ytTht-0D5oif0cAGXSPjPSN\r\nContent-Disposition: form-data; name=\"skill\"\r\n\r\nruby\r\n----------------------------_ytTht-0D5oif0cAGXSPjPSN\r\nContent-Disposition: form-data; name=\"skill\"\r\n\r\ncrystal\r\n----------------------------_ytTht-0D5oif0cAGXSPjPSN\r\nContent-Disposition: form-data; name=\"avatar\"; filename=\"avatar.png\"\r\n\r\nimage binary data\n\r\n----------------------------_ytTht-0D5oif0cAGXSPjPSN--"
  # form.headers # => HTTP::Headers{"Content-Type" => "multipart/form-data; boundary=\"--------------------------SS0a9QKeM_6fcj2CE5D4d0LQ\""}
  # ```
  module FormData
    # FormData factory. Automatically selects best type depending on given `data` Hash
    def self.create(data : Hash(String, Options::Type) = {} of String => Options::Type) : Halite::Request::Data
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

        Halite::Request::Data.new(io.to_s, headers: {"Content-Type" => builder.content_type})
      else
        content_type = "application/x-www-form-urlencoded"
        body = HTTP::Params.escape(data)

        Halite::Request::Data.new(body, headers: {"Content-Type" => content_type})
      end
    end

    # Tells whenever data contains multipart data or not.
    private def self.multipart?(data : Hash(String, Options::Type)) : Bool
      data.any? do |_, v|
        next true if v.is_a?(File)
      end
    end
  end
end
