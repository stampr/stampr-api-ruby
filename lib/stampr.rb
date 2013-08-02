require "rest_client"
require "json"

require_relative "stampr/utilities"
require_relative "stampr/exceptions"

require_relative "stampr/client"
require_relative "stampr/batch"
require_relative "stampr/config"
require_relative "stampr/mailing"
require_relative "stampr/version"

# Ruby interface to the Stampr API.
module Stampr
  class << self
    # @return [Stampr::Client] The client, which stores username and password. This needn't be used directly.
    attr_reader :client

    # Authenticate your Stampr account with username and password.
    #
    # @param username [String]
    # @param password [String]
    # @return [Stampr::Client]
    def authenticate(username, password)
      @client = Client.new username, password
    end

    # Send a simple HTML or PDF email, in its own batch and default config (unless :batch and/or :config options are used).
    #
    # @example
    #   Stampr.authenticate "user", "pass"
    #   Stampr.mail return_address, address1, "<html><body><p>Hello world!</p></body></html>"
    #   Stampr.mail return_address, address2, "<html><body><p>Goodbye world!</p></body></html>"
    #
    # @param from [String] Return address.
    # @param to [String] Address
    # @param body [String] HTML or PDF data.
    # @option options :config [Stampr::Config]
    # @option options :batch [Stampr::Batch]
    # @return [Stampr::Mailing] The mailing object representing the mail sent.
    def mail(from, to, body, options={})
      @client.mail from, to, body, options
    end
  end
end
