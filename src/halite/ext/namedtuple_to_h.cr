struct NamedTuple
  # Returns a `Hash` with the keys and values in this named tuple.
  #
  # TODO: This is fix bug, It will remove if PR is merged https://github.com/crystal-lang/crystal/pull/6628
  def to_h
    # raise "Can't convert an empty NamedTuple to a Hash" if empty?

    {% if T.size > 0 %}
    {
      {% for key in T %}
        {{key.symbolize}} => self[{{key.symbolize}}],
      {% end %}
    }
    {% else %}
      {} of NoReturn => NoReturn
    {% end %}
  end
end
