module Halite
  # Generic error
  class Error < Exception; end

  # Generic Connection error
  class ConnectionError < Error; end

  # Generic Request error
  class RequestError < Error; end

  # Generic Response error
  class ResponseError < Error; end

  # The method given was not understood
  class UnsupportedMethodError < RequestError; end

  # The scheme given was not understood
  class UnsupportedSchemeError < RequestError; end

  # Requested to do something when we're in the wrong state
  class StateError < RequestError; end

  # Generic Timeout error
  class TimeoutError < RequestError; end

  # Notifies that we reached max allowed redirect hops
  class TooManyRedirectsError < ResponseError; end

  # Notifies that following redirects got into an endless loop
  class EndlessRedirectError < TooManyRedirectsError; end

  # The MIME type(adapter) given was not understood
  class UnRegisterAdapterError < ResponseError; end

  # Generic API error
  class APIError < ResponseError
    getter uri
    getter status_code
    getter status_message

    def initialize(@message : String? = nil, @status_code : Int32? = nil, @uri : URI? = nil)
      if status_code = @status_code
        status_message = [HTTP.default_status_message_for(status_code).downcase]
        status_message << "error"
        status_message << "with url: #{@uri.not_nil!}" if @uri

        @message ||= "#{status_code} #{status_message.join(" ")} "
      end

      super(@message)
    end
  end

  # 4XX client error
  class ClientError < APIError; end

  # 5XX server error
  class ServerError < APIError; end
end
