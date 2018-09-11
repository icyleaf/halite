struct NamedTuple
  # Returns a `Hash` with the keys and values in this named tuple.
  #
  # TODO: Remove it when Crystal 0.27.0 is released. https://github.com/crystal-lang/crystal/pull/6628
  def to_h
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
