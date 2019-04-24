module HTTP
  # This is **extension**  apply in Halite.
  struct Params
    # Returns the given key value pairs as a url-encoded query.
    #
    # Every parameter added is directly written to an IO, where keys and values are properly escaped.
    #
    # ```
    # HTTP::Params.encode({
    #   "name"    => "Lizeth Gusikowski",
    #   "skill"   => ["ruby", "crystal"],
    #   "company" => {
    #     "name" => "Keeling Inc",
    #   },
    #   "avatar" => File.open("avatar_big.png"),
    # })
    # # => "name=Lizeth+Gusikowski&skill=ruby&skill=crystal&company=%7B%22name%22+%3D%3E+%22Keeling+Inc%22%7D&avatar=avatar_big.png"
    # ```
    def self.encode(hash : Hash) : String
      ::HTTP::Params.build do |form|
        hash.each do |key, value|
          key = key.to_s
          case value
          when Array
            value.each do |item|
              form.add("#{key}", item.to_s)
            end
          when File
            form.add(key, value.as(File).path)
          when Hash
            value.each do |hkey, hvalue|
              form.add("#{key}[#{hkey}]", hvalue.to_s)
            end
          else
            form.add(key, value.to_s)
          end
        end
      end
    end

    # Returns the given key value pairs as a url-encoded query.
    #
    # Every parameter added is directly written to an IO, where keys and values are properly escaped.
    #
    # ```
    # HTTP::Params.encode({
    #   name: "Lizeth Gusikowski",
    #   skill: ["ruby", "crystal"],
    #   company: {
    #     name: "Keeling Inc",
    #   },
    #   avatar: File.open("avatar_big.png"
    # })
    # # => "name=Lizeth+Gusikowski&skill=ruby&skill=crystal&company=%7B%22name%22+%3D%3E+%22Keeling+Inc%22%7D&avatar=avatar_big.png"
    # ```
    def self.encode(named_tuple : NamedTuple) : String
      encode(named_tuple.to_h)
    end

    # Returns the given key value pairs as a url-encoded query.
    #
    # Every parameter added is directly written to an IO, where keys and values are properly escaped.
    #
    # ```
    # HTTP::Params.encode(
    #   name: "Lizeth Gusikowski",
    #   skill: ["ruby", "crystal"],
    #   company: {
    #     name: "Keeling Inc",
    #   },
    #   avatar: File.open("avatar_big.png"
    # )
    # # => "name=Lizeth+Gusikowski&skill=ruby&skill=crystal&company=%7B%22name%22+%3D%3E+%22Keeling+Inc%22%7D&avatar=avatar_big.png"
    # ```
    def self.encode(**named_tuple) : String
      encode(named_tuple)
    end
  end
end
