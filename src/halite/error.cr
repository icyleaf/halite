module Halite
  # Generic error
  class Error < Exception; end

  # Generic Connection error
  class ConnectionError < Error; end

  # Generic Request error
  class RequestError < Error; end

  # The method given was not understood
  class UnsupportedMethodError < RequestError; end

  # The scheme given was not understood
  class UnsupportedSchemeError < RequestError; end

  # Requested to do something when we're in the wrong state
  class StateError < RequestError; end

  # Generic Timeout error
  class TimeoutError < RequestError; end

  # Generic Response error
  class ResponseError < Error; end

  # Notifies that we reached max allowed redirect hops
  class TooManyRedirectsError < ResponseError; end

  # Notifies that following redirects got into an endless loop
  class EndlessRedirectError < TooManyRedirectsError; end

  # The MIME type(adapter) given was not understood
  class UnRegisterAdapterError < ResponseError; end
end
