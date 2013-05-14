module Stampr
  class Client
    BASE_URI = "https://testing.dev.stam.pr/api"

    # @param username [String]
    # @param password [String]
    def initialize(username, password)
      @client = RestClient::Resource.new BASE_URI, username, password
    end

    # @param from [String]
    # @param to [String]
    # @param body [String]
    #
    # @option :config [Stampr::Config]
    # @option :batch [Stampr::Batch]
    def send(from, to, body, options={})
      raise TypeError, "from must be a non-empty String" unless from.is_a?(String) && !from.empty?
      raise TypeError, "to must be a non-empty String" unless to.is_a?(String) && !to.empty?
      raise TypeError, "body must be a String" unless body.is_a? String

      Mailing.new options do |m|
        m.to = to
        m.from = from
        m.body = body
      end
    end
  end
end