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
      # @overload [](time_period, options = {})
      #   Get the mailing between two times, optionally only with a specific
      #   status and/or in a specific batch (:batch OR :batch_id option should be used)
      #
      #   @param time_period [Range<Time/DateTime>] Time period to get mailings for.
      #   @option options :status [:processing, :hold, :archive] Status of mailings to find.
      #   @option options :batch_id [Integer] ID of batch to retrieve mailings from.
      #   @option options :batch [Stampr::Batch] Batch to retrieve mailings from.
      #
      #   @return [Array<Stampr::Mailing>]
      def [](*args)
        case args[0]
        when Integer
          unless args.size == 1
            raise ArgumentError, "Only expected a single argument when searching by ID" 
          end

          id = args[0]

          unless id.is_a?(Integer) && id > 0
            raise TypeError, "id should be a positive Integer" 
          end

          mailings = Stampr.client.get ["mailings", id]
          mailing = mailings.first
          self.new symbolize_hash_keys(mailing)

        when Range
          unless args.size.between? 1, 2
            raise ArgumentError, "Expected one or two arguments when searching over time period"
          end

          range = args[0]
          options = args[1] || {}

          unless options.nil? or options.is_a? Hash
            raise TypeError, "options, if present, should be a Hash" 
          end

          from, to = range.first, range.last
          unless from.respond_to? :to_time and to.respond_to? :to_time
            raise TypeError, "Can only use a range of Time/DateTime"
          end

          status, batch_id, batch = options[:status], options[:batch_id], options[:batch]

          if status
            unless status.is_a? Symbol
              raise TypeError, ":status option should be one of #{Batch::STATUSES.map(&:inspect).join ", "}" 
            end

            unless Batch::STATUSES.include? status
              raise ArgumentError, ":status option should be one of #{Batch::STATUSES.map(&:inspect).join ", "}" 
            end
          end

          if batch and batch_id
            raise ArgumentError, "Expected :batch OR :batch_id options"
          end

          if batch_id
            unless batch_id.is_a? Integer and batch_id > 0
              raise TypeError, ":status option should be a positive Integer" 
            end
          end

          if batch
            unless batch.is_a? Batch
              raise TypeError, ":batch option should be a Stampr::Batch" 
            end

            batch_id = batch.id
          end

          search = if batch_id and status
            ["batches", batch_id, "with", status]
          elsif batch_id
            ["batches", batch_id, "browse"]
          elsif status
            ["mailings", "with", status]      
          else
            ["mailings", "browse"]   
          end

          search += [from.to_time.utc.iso8601, to.to_time.utc.iso8601]

          all_mailings = []
          i = 0

          loop do
            mailings = Stampr.client.get (search + [i])

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
      if options.key?(:batch_id) && options.key?(:batch)
        raise ArgumentError, "Must supply :batch_id OR :batch options" 
      end

      @batch_id = if options.key? :batch_id
        unless options[:batch_id].is_a? Integer
          raise TypeError, ":batch_id option must be an Integer" 
        end
        options[:batch_id]

      elsif options.key? :batch
        unless options[:batch].is_a? Stampr::Batch
          raise TypeError, ":batch option must be an Stampr::Batch"
        end
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
      unless value.nil? or value.is_a? String
        raise TypeError, "address must be a String"
      end

      @address = value
    end


    # Set the return address for the mail.
    def return_address=(value)
      unless value.nil? or value.is_a? String
        raise TypeError, "return_address must be a String" 
      end

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