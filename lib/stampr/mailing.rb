module Stampr
  class Mailing
    FORMATS = [:json, :html, :pdf, :none]

    attr_accessor :address, :return_address, :format, :data, :batch_id

    class << self
      # Get the batch with the specific ID.
      # @return [Stampr::Mailing]
      def [](id)
        raise TypeError, "id should be a positive Integer" unless id.is_a?(Integer) && id > 0

        mailings = Stampr.client.get ["mailings", id]
        mailing = mailings.first
        self.new Stampr.symbolize_hash_keys(mailing)       
      end
    end


    # @option :batch [Stampr::Batch]
    # @option :address [String]
    # @option :return_address [String]
    # @option :data [String, Hash] Hash for mail merge, String for HTML or PDF format.
    def initialize(options = {})
      raise ArgumentError, "Must supply :batch_id OR :batch options" if options.key?(:batch_id) && options.key?(:batch)

      @batch_id = if options.key? :batch_id
        raise TypeError, ":batch_id option must be an Integer" unless options[:batch_id].is_a? Integer
        options[:batch_id]

      elsif options.key? :batch
        raise TypeError, ":batch option must be an Stampr::Batch" unless options[:batch].is_a? Stampr::Batch
        options[:batch].id

      else
        # Create a batch just for this mailing (not accessible outside this object).
        @batch = Batch.new
        @batch.id        
      end

      self.address = options[:address] || nil
      self.return_address = options[:return_address] || options[:returnaddress] || nil
      self.data = options[:data] || nil
      @id = options[:mailing_id] || nil
    end


    def address=(value)
      raise TypeError, "address must be a String" unless value.nil? or value.is_a? String

      @address = value
    end


    def return_address=(value)
      raise TypeError, "return_address must be a String" unless value.nil? or value.is_a? String

      @return_address = value
    end


    def data=(value)
      old_data, @data = @data, value
      begin
        format # Just read format to check that the format is good.
      rescue TypeError => ex
        @data = old_data
        raise ex
      end
      @data
    end


    def id
      mail unless @id
      @id
    end


    def format
      case data
      when Hash
        :json
      when String
        # Check if the string has a PDF header.
        if data =~ /\A%PDF/
          :pdf
        else
          :html
        end
      when NilClass
        :none
      else
        raise TypeError, "Bad format for data"
      end
    end


    def mail
      return if @id # Don't re-create if it already exists.

      raise APIError, "address required before mailing" unless address
      raise APIError, "return_address required before mailing" unless return_address

      params = {
          batch_id: batch_id,
          address: address,
          returnaddress: return_address,
          format: format,
      }

      case format
      when :json
        params[:data] = data.to_json
      when :html
         params[:data] = data
      when :pdf
        params[:data] = data # TODO: encode this? Base64?
      end

      result = Stampr.client.post "mailings", params
                                  
      @id = result["mailing_id"]

      self
    end


    # @return true on successful deletion.
    def delete
      raise APIError, "Can't #delete before #create" unless @id

      id, @id = @id, nil

      Stampr.client.delete ["mailings", id]

      true
    end
  end
end