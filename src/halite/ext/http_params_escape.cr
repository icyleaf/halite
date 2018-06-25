module HTTP
  struct Params
    # Returns the given key value pairs as a url-encoded query.
    #
    # Every parameter added is directly written to an IO, where keys and values are properly escaped.
    #
    # ```
    # HTTP::Params.escape({
    #   "name"    => "Lizeth Gusikowski",
    #   "skill"   => ["ruby", "crystal"],
    #   "company" => {
    #     "name" => "Keeling Inc",
    #   },
    #   "avatar" => File.open("avatar_big.png"),
    # })
    # # => "name=Lizeth+Gusikowski&skill=ruby&skill=crystal&company=%7B%22name%22+%3D%3E+%22Keeling+Inc%22%7D&avatar=avatar_big.png"
    # ```
    def self.escape(data : (Hash(String, _) | NamedTuple)) : String
      ::HTTP::Params.build do |form|
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

    # Returns the given key value pairs as a url-encoded query.
    #
    # Every parameter added is directly written to an IO, where keys and values are properly escaped.
    #
    # ```
    # HTTP::Params.escape({
    #   "name"    => "Lizeth Gusikowski",
    #   "skill"   => ["ruby", "crystal"],
    #   "company" => {
    #     "name" => "Keeling Inc",
    #   },
    #   "avatar" => File.open("avatar_big.png"),
    # })
    # # => "name=Lizeth+Gusikowski&skill=ruby&skill=crystal&company=%7B%22name%22+%3D%3E+%22Keeling+Inc%22%7D&avatar=avatar_big.png"
    # ```
    def self.escape(data : (Hash(String, Halite::Options::Type) | NamedTuple)) : String
      ::HTTP::Params.build do |form|
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

    # Return `true` if params is empty.
    #
    # TODO: remove if crystal merge and dump new version wih [PL#6241](https://github.com/crystal-lang/crystal/pull/6241/).
    delegate empty?, to: raw_params
  end
end
