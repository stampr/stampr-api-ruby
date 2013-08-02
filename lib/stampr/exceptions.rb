module Stampr
  # General error with the Stampr gem.
  class Error < StandardError; end

  # Problem with the HTTP connection or authentication.
  class HTTPError < Error; end

  # Bad request to the server.
  class RequestError < Error; end

  # Problem with interfacing with rules of the API.
  class APIError < Error; end

  # User attempts to alter read-only attribute.
  class ReadOnlyError < Error
    def initialize(attribute)
      super("can't modify attribute: #{attribute}")
    end
  end
end