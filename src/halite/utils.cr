module Halite
  module Utils
    def encode_www_form(data : (Hash(String, Options::Type) | NamedTuple))
      HTTP::Params.build do |form|
        data.each do |k, v|
          k = k.to_s
          case v
          when Array
            v.each do |e|
              form.add(k, e.to_s)
            end
          when File
            form.add(k, v.as(File).path)
          else
            form.add(k, v.to_s)
          end
        end
      end
    end
  end
end
