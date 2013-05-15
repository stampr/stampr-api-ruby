require "rest_client"
require "json"

require_relative "stampr/client"
require_relative "stampr/batch"
require_relative "stampr/config"
require_relative "stampr/mailing"
require_relative "stampr/version"

module Stampr
  class Error < StandardError; end
  class HTTPError < Error; end
  class RequestError < Error; end
  class APIError < Error; end

  class << self
    attr_reader :client

    def authenticate(username, password)
      @client = Client.new username, password
    end

    def mail(from, to, body, options={})
      @client.mail from, to, body, options
    end
  end
end
