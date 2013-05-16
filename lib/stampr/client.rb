require 'singleton'

module Stampr
  # Client that handles the actual RESTful actions.
  class Client
    BASE_URI = "https://testing.dev.stam.pr/api"

    # @param username [String]
    # @param password [String]
    def initialize(username, password)
      @client = RestClient::Resource.new BASE_URI, username, password
    end

    # Send a simple HTML or PDF email, in its own batch and default config (unless :batch and/or :config options are used).
    #
    # @see Stampr.mail
    #
    # @example
    #   client = Stampr::Client.new "user", "pass"
    #   client.mail return_address, address1, "<html><body><p>Hello world!</p></body></html>"
    #   client.mail return_address, address2, "<html><body><p>Goodbye world!</p></body></html>"
    #
    # @param from [String] Return address.
    # @param to [String] Address
    # @param body [String] HTML or PDF data.
    # @option options :config [Stampr::Config]
    # @option options :batch [Stampr::Batch]
    # @return [Stampr::Mailing] The mailing object representing the mail sent.
    def mail(from, to, body, options={})
      raise TypeError, "from must be a non-empty String" unless from.is_a?(String) && !from.empty?
      raise TypeError, "to must be a non-empty String" unless to.is_a?(String) && !to.empty?
      raise TypeError, "body must be a String" unless body.is_a? String

      config = options[:config] || Config.new
      batch = options[:batch] || Batch.new(config: config)

      Mailing.new batch: batch do |m|
        m.address = to
        m.return_address = from
        m.data = body
      end
    end


    # @return [Time] Time on the server.
    def server_time
      result = get "test/ping"
      Time.parse result["pong"]
    end


    # @return [Float] Number of seconds to/from server.
    def ping
      sent = Time.now
      get %"test/ping"
       
      (Time.now - sent).fdiv 2
    end

    # Send a HTTP GET request.
    def get(path)
      api :get, path
    end

    # Send a HTTP POST request.
    def post(path, params = {})
      api :post, path, params
    end

    # Send a HTTP DELETE request.
    def delete(path)
      api :delete, path
    end


    private
    # Actually send a RESTful action to path.
    def api(action, path, params = nil)
      path = Array(path).join "/"
      
      response = if params
         @client[path].public_send action, params, accept: :json
      else
        @client[path].public_send action, accept: :json
      end

      JSON.parse response.body
    rescue RestClient::BadRequest => ex
      raise RequestError, ex.message
    rescue RestClient::Exception => ex
      raise HTTPError, ex.message
    end
  end
end