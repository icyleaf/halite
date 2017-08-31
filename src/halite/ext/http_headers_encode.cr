module Halite::Ext::HTTPHeaders::Escape
  # Returns the given key value pairs as HTTP Headers
  #
  # Every parameter added is directly written to an IO, where keys are properly escaped.
  #
  # ```
  # HTTP::Headers.escape({
  #   content_type: "application/json",
  # })
  # # => "HTTP::Headers{"Content-Type" => "application/json"}"
  #
  # HTTP::Headers.escape({
  #   "conTENT-type": "application/json",
  # })
  # # => "HTTP::Headers{"Content-Type" => "application/json"}"
  # ```
  def escape(data : Hash(String, _) | NamedTuple) : HTTP::Headers
    ::HTTP::Headers.new.tap do |builder|
      data = data.is_a?(NamedTuple) ? data.to_h : data
      data.each do |key, value|
        key = key.to_s.gsub("_", "-").split("-").map { |v| v.capitalize }.join("-")
        value = value.to_s

        builder.add(key, value)
      end
    end
  end
end

module HTTP
  struct Headers
    extend Halite::Ext::HTTPHeaders::Escape
  end
end
