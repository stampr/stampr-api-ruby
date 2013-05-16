require "rest_client"
require "json"

require_relative "stampr/utilities"

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
    # [Stampr::Client] The client, which stores username and password.
    attr_reader :client

    # Authenticate your Stampr account with username and password.
    # @param username [String]
    # @param password [String]
    def authenticate(username, password)
      @client = Client.new username, password
    end

    # Send a simple HTML or PDF email, in its own batch (unless batch is specified).
    #
    # @example
    #   Stampr.mail return_address, address, html_body
    #
    # @param from [String] Return address.
    # @param to [String] Address
    # @param body [String] HTML or PDF data.
    # @option :config [Stampr::Config]
    # @option :batch [Stampr::Batch]
    def mail(from, to, body, options={})
      @client.mail from, to, body, options
    end
  end
end
