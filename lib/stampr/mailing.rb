module Stampr
  class Mailing
    FORMATS = [:json, :html, :pdf, :none]
    DEFAULT_FORMAT = :none

    attr_accessor :address, :return_address, :format, :data, :batch_id, :id

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


    def initialize(options = {})
      @batch_id = if options[:batch_id] and not options[:batch]
        raise TypeError, ":batch_id option must be an Integer" unless options[:batch_id].is_a? Integer
        options[:batch_id]

      elsif options[:batch]
        raise TypeError, ":batch option must be an Stampr::Batch" unless options[:batch].is_a? Stampr::Batch
        options[:batch].id

      else
        raise ArgumentError, "Must supply :batch_id OR :batch options"
      end

      self.address = options[:address] || nil
      self.return_address = options[:return_address] || options[:returnaddress] || nil
      self.format = (options[:format] || DEFAULT_FORMAT).to_sym
      self.data = options[:data] || nil
      @id = options[:mailing_id] || nil
    end


    def address=(value)
      raise TypeError, "template must be a String" unless value.nil? or value.is_a? String

      @address = value
    end


    def return_address=(value)
      raise TypeError, "template must be a String" unless value.nil? or value.is_a? String

      @return_address = value
    end


    def format=(value)
      raise TypeError, "format must be a Symbol" unless value.is_a? Symbol
      raise ArgumentError, "format must be one of: #{FORMATS.map(&:inspect).join(", ")}" unless FORMATS.include? value

      @format = value
    end


    def data=(value)
      @data = value
    end


    def mail
      return if @id # Don't re-create if it already exists.

      params = {
          batch_id: batch_id,
          address: address,
          returnaddress: return_address,
          format: format,
      }

      case format
      when :json
        raise APIError, "data expected as Hash for conversion to json" unless data.is_a? Hash
        params[:data] = data.to_json
      when :html
        raise APIError, "data expected as String containing HTML" unless data.is_a? String
        params[:data] = data
      when :pdf
        raise APIError, "data expected as binary String containing PDF data" unless data.is_a? String
        raise NotImplementedError, "Not sure what encoding to give PDF data."
        params[:data] = data # TODO: encode this? Base64?
      when :none
        raise APIError, "data provided, but format is :none" unless data.nil?
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