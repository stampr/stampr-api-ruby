require 'base64'
require 'digest/md5'
require 'time'

module Stampr
  # An individual piece of mail, within a Stampr::Batch
  class Mailing
    extend Utilities

    attr_accessor :address, :return_address, :format, :data, :batch_id

    class << self
      # @overload [](id)
      #   Get the mailing with the specific ID.
      #
      #   @param id [Integer] ID of mailing to retreive.
      #
      #   @return [Stampr::Mailing]
      #
      # @overload [](time_period)
      #   Get the mailing between two times.
      #
      #   @param time_period [Range<Time/DateTime>] Time period to get mailings for.
      #
      #   @return [Array<Stampr::Mailing>]
      def [](index)
        case index
        when Integer
          raise TypeError, "index should be a positive Integer" unless index.is_a?(Integer) && index > 0

          mailings = Stampr.client.get ["mailings", index]
          mailing = mailings.first
          self.new symbolize_hash_keys(mailing)

        when Range
          from, to = index.first, index.last
          unless from.respond_to? :to_time and to.respond_to? :to_time
            raise TypeError, "Can only use a range of Time/DateTime"
          end

          all_mailings = []
          i = 0

          loop do
            mailings = Stampr.client.get ["mailings", "browse", from.to_time.utc.iso8601, to.to_time.utc.iso8601, i]

            break if mailings.empty?

            all_mailings.concat mailings.map {|m| self.new symbolize_hash_keys(m) }

            i += 1
          end

          all_mailings

        else
          raise TypeError, "index must be a positive Integer or Time/DateTime range"
        end     
      end
    end


    # @option options :batch [Stampr::Batch]
    # @option options :batch_id [Integer]
    # @option options :address [String]
    # @option options :return_address [String]
    # @option options :data [String, Hash] Hash for mail merge, String for HTML or PDF format.
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

      # Decode the data if it has been recieved through a query. Not if the user set it.
      self.data = if options.key? :data
        if options.key? :mailing_id
          # Check MD5 if provided.
          if options.key? :md5
            if options[:md5] != Digest::MD5.hexdigest(options[:data])
              raise ArgumentError, "MD5 digest does not match data"
            end
          end

          Base64.decode64 options[:data]
        else
          options[:data]
        end
      else
        nil
      end

      @id = options[:mailing_id] || nil

      if block_given?
        yield self 
        mail
      end
    end


    # Set the address to send mail to.
    def address=(value)
      raise TypeError, "address must be a String" unless value.nil? or value.is_a? String

      @address = value
    end


    # Set the return address for the mail.
    def return_address=(value)
      raise TypeError, "return_address must be a String" unless value.nil? or value.is_a? String

      @return_address = value
    end


    # Set the data (HTML string, mail-merge Hash, PDF data or nil)
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

    # Get the id of the mailing. Calling this will mail the mailing first, if required.
    #
    # @return [Integer]
    def id
      mail unless @id
      @id
    end


    # The format of the mailing data.
    #
    # @return [:json, :pdf, :html, :none]
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


    # Mail the mailing on the server.
    def mail
      raise APIError, "Already mailed" if @id
      
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
        params[:data] = Base64.encode64 data.to_json
      when :html, :pdf
        params[:data] = Base64.encode64 data
      end

      if params.key? :data
        params[:md5] = Digest::MD5.hexdigest params[:data]
      end

      result = Stampr.client.post "mailings", params
                                  
      @id = result["mailing_id"]

      self
    end


    # Delete the mailing on the server.
    #
    # @return true on successful deletion.
    def delete
      raise APIError, "Can't #delete before #create" unless @id

      id, @id = @id, nil

      Stampr.client.delete ["mailings", id]

      true
    end
  end
end