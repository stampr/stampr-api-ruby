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
    # @option :batch [Stampr::Batch]
    def send(from, to, body, options={})
      raise TypeError, "from must be a non-empty String" unless from.is_a?(String) && !from.empty?
      raise TypeError, "to must be a non-empty String" unless to.is_a?(String) && !to.empty?
      raise TypeError, "body must be a String" unless body.is_a? String

      batch = options[:batch] || Batch.new

      Mailing.new batch: batch do |m|
        m.to = to
        m.from = from
        m.body = body
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


    def get(path, params = {})
      path = Array(path).join "/"
      response = @client[path].get params, accept: :json
      JSON.parse response.body
    rescue RestClient::BadRequest => ex
      raise RequestError, ex.message
    rescue RestClient::Exception => ex
      raise HTTPError, ex.message
    end


    def post(path, params = {})
      path = Array(path).join "/"
      response = @client[path].post params, accept: :json
      JSON.parse response.body
    rescue RestClient::BadRequest => ex
      raise RequestError, ex.message
    rescue RestClient::Exception => ex
      raise HTTPError, ex.message
    end


    def delete(path, params = {})
      path = Array(path).join "/"
      resonse = @client[path].delete params, accept: :json
      JSON.parse response.body
    rescue RestClient::BadRequest => ex
      raise RequestError, ex.message
    rescue RestClient::Exception => ex
      raise HTTPError, ex.message
    end
  end
end