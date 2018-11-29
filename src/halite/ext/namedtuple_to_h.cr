{% if Crystal::VERSION < "0.27.0" %}
  struct NamedTuple
    # Returns a `Hash` with the keys and values in this named tuple.
    #
    # NOTE: This is **extension**  apply in Halite and under v0.27.0. See https://github.com/crystal-lang/crystal/pull/6628
    def to_h
      \{% if T.size > 0 %}
        {
          \{% for key in T %}
            \{{key.symbolize}} => self[\{{key.symbolize}}],
          \{% end %}
        }
      \{% else %}
        {} of NoReturn => NoReturn
      \{% end %}
    end
  end
{% end %}
