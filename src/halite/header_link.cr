module Halite
  # HeaderLink
  #
  # ref: [https://tools.ietf.org/html/rfc5988](https://tools.ietf.org/html/rfc5988)
  struct HeaderLink
    # Header link parser
    def self.parse(raw : String, uri : URI? = nil) : Hash(String, Halite::HeaderLink)
      links = {} of String => HeaderLink
      raw.split(/,\s*</).each do |rel|
        head_link = parse_link(rel, uri)
        links[head_link.rel] = head_link
      end
      links
    end

    private def self.parse_link(raw, uri)
      params = {} of String => String
      if raw.includes?(";")
        target, attrs = raw.split(";", 2)
        rel = target = target.gsub(/[<> '\"]/, "").strip
        unless attrs.strip.empty?
          attrs.split(";").each do |attr|
            next if attr.strip.empty?
            key, value = attr.split("=")
            key = key.gsub(/['\"]/, "").strip
            next if params.has_key?(key)

            value = value.gsub(/['\"]/, "").strip
            params[key] = value
          end

          if name = params.delete("rel")
            rel = name
            if target == "/"
              target = rel
            elsif target.starts_with?("/") && (uri_local = uri)
              full_target = uri_local.dup
              full_target.path = target
              target = full_target.to_s
            end
          end
        end
      else
        rel = target = raw.gsub(/[<> '\"]/, "").strip
      end

      new(rel, target, params)
    end

    getter rel, target, params

    def initialize(@rel : String, @target : String, @params : Hash(String, String))
    end

    def to_s(io)
      io << target
    end
  end
end
