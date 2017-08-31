# :nodoc:
class File
  def to_json(json : JSON::Builder) : String
    json.string(to_s)
  end
end
