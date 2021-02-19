module Halite
  # Limit Rate
  #
  # ref: [https://tools.ietf.org/id/draft-polli-ratelimit-headers-00.html](https://tools.ietf.org/id/draft-polli-ratelimit-headers-00.html)
  #
  # ```
  # > X-RateLimit-Limit: 5000
  # > X-RateLimit-Remaining: 4987
  # > X-RateLimit-Reset: 1350085394
  # ```
  struct RateLimit
    RATELIMIT_LIMIT     = "X-RateLimit-Limit"
    RATELIMIT_REMAINING = "X-RateLimit-Remaining"
    RATELIMIT_RESET     = "X-RateLimit-Reset"

    def self.parse(headers : HTTP::Headers)
      limit = headers[RATELIMIT_LIMIT]?.try &.to_i
      remaining = headers[RATELIMIT_REMAINING]?.try &.to_i
      reset = headers[RATELIMIT_RESET]?.try &.to_i
      return if !limit && !remaining && !reset

      new(limit, remaining, reset)
    end

    getter limit, remaining, reset

    def initialize(@limit : Int32?, @remaining : Int32?, @reset : Int32?)
    end
  end
end
