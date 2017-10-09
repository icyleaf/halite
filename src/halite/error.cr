module Halite
  class Error < Exception; end

  class RequestError < Error; end

  class StateError < RequestError; end

  class TimeoutError < RequestError; end

  class ConnectionError < RequestError; end

  class ResponseError < Error; end

  class TooManyRedirectsError < ResponseError; end

  # Notifies that following redirects got into an endless loop
  class EndlessRedirectError < TooManyRedirectsError; end
end
