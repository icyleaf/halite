# :nodoc:
class File
  def to_json(json : JSON::Builder)
    json.string(to_s)
  end
end
