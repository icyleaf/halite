module HTTP
  # This is **extension** apply in Halite.
  struct Headers
    # Returns the given key value pairs as HTTP Headers
    #
    # Every parameter added is directly written to an IO, where keys are properly escaped.
    #
    # ```
    # HTTP::Headers.encode({
    #   content_type: "application/json",
    # })
    # # => "HTTP::Headers{"Content-Type" => "application/json"}"
    #
    # HTTP::Headers.encode({
    #   "conTENT-type": "application/json",
    # })
    # # => "HTTP::Headers{"Content-Type" => "application/json"}"
    # ```
    def self.encode(data : Hash(String, _) | NamedTuple) : HTTP::Headers
      ::HTTP::Headers.new.tap do |builder|
        data = data.is_a?(NamedTuple) ? data.to_h : data
        data.each do |key, value|
          key = key.to_s.gsub("_", "-").split("-").map { |v| v.capitalize }.join("-")
          # skip invalid value of content length
          next if key == "Content-Length" && !(value =~ /^\d+$/)

          builder.add key, value.is_a?(Array(String)) ? value : value.to_s
        end
      end
    end

    # Same as `#encode`
    def self.encode(**data)
      encode(data)
    end

    # Similar as `Hahs#to_h` but return `String` if it has one value of the key.
    #
    # ```
    # headers = HTTP::Headers{"Accepts" => ["application/json", "text/html"], "Content-Type" => ["text/html"]}
    # headers["Accepts"]      # => ["application/json", "text/html"]
    # headers["Content-Type"] # => "text/html"
    # ```
    def to_flat_h
      @hash.each_with_object({} of String => String | Array(String)) do |(key, values), obj|
        obj[key.name] = case values
                        when String
                          values.as(String)
                        when Array
                          values.size == 1 ? values[0].as(String) : values.as(Array(String))
                        else
                          raise Halite::Error.new("Not support type `#{values.class} with value: #{values}")
                        end
      end
    end
  end
end
