require 'base64'
require 'digest/md5'
require 'time'

module Stampr
  # An individual piece of mail, within a Stampr::Batch
  # 
  # @!attribute [r] batch_id
  #   @return [Integer] The ID of the Batch associated with the mailing.
  #
  # @!attribute [rw] address
  #   @return [String] Address to send mail to.
  #
  # @!attribute [rw] return_address
  #   @return [String] Return address for mail
  #
  # @!attribute [r] format
  #   @return [String] Format of the data
  #
  # @!attribute [rw] data
  #   @return [String, Hash] PDF data string, HTML document string, or key/value hash (for mail merge)
  #
  # @!attribute [r] status
  #   @return [nil, :received, :render, :error, :queued, :assigned, :processing, :printed, :shipped] Status of the mailing (nil before it is sent).
  class Mailing
    include Utilities

    STATUSES = [:received, :render, :error, :queued, :assigned, :processing, :printed, :shipped]

    attr_reader :address, :return_address, :format, :data, :batch_id, :status

    class << self
      # Get the mailing with the specific ID.
      #
      # @example
      #   mailing = Stampr::Mailing[123123]
      #
      # @param id [Integer] ID of mailing to retreive.
      #
      # @return [Stampr::Mailing]
      def [](id)
        unless id.is_a?(Integer) && id > 0
          raise TypeError, "id should be a positive Integer" 
        end

        mailings = Stampr.client.get ["mailings", id]
        mailing = mailings.first

        self.new symbolize_hash_keys(mailing)
      end
      

      # Get the mailing between two times, optionally only with a specific
      # status and/or in a specific batch (:batch OR :batch_id option should be used)
      #
      # @example
      #   time_period = Time.new(2012, 1, 1, 0, 0, 0)..Time.now
      #   my_batch = Stampr::Batch[1234]
      #
      #   mailings = Stampr::Mailing[time_period]
      #   mailings = Stampr::Mailing[time_period, status: :processing]
      #   mailings = Stampr::Mailing[time_period, batch: my_batch]
      #   mailings = Stampr::Mailing[time_period, status: :processing, batch: my_batch]
      #
      # @param period [Range<Time/DateTime>] Time period to get mailings for.
      # @option options :status [:received :render, :error, :queued, :assigned, :processing, :printed, :shipped] Status of mailings to find.
      # @option options :batch [Stampr::Batch] Batch to retrieve mailings from.
      #
      # @return [Array<Stampr::Mailing>]
      def browse(period, options = {})
        unless period.is_a? Range
          raise TypeError, "period should be a Range of Time/DateTime"
        end

        from, to = period.first, period.last
        unless from.respond_to? :to_time and to.respond_to? :to_time
          raise TypeError, "period should be a Range of Time/DateTime"
        end

        status, batch = options[:status], options[:batch]

        if status
          unless status.is_a? Symbol
            raise TypeError, ":status option should be one of #{STATUSES.map(&:inspect).join ", "}" 
          end

          unless STATUSES.include? status
            raise ArgumentError, ":status option should be one of #{STATUSES.map(&:inspect).join ", "}" 
          end
        end

        batch_id = if batch
          unless batch.is_a? Stampr::Batch
            raise TypeError, ":batch option should be a Stampr::Batch" 
          end

          batch.id
        else
          nil
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
      end
    end

    # Has the Batch been created already?
    def created?; !@id.nil?; end

    # @option options :batch [Stampr::Batch]
    # @option options :address [String]
    # @option options :return_address [String]
    # @option options :data [String, Hash] Hash for mail merge, String for HTML or PDF format.
    # @yield [Stampr::Mailing] self
    # @raise [ArgumentError, TypeError]
    def initialize(options = {})
      if options.key?(:batch_id) && options.key?(:batch)
        raise ArgumentError, "Must supply :batch_id OR :batch options" 
      end

      # :batch_id is used internally. Shouldn't be used by end-user.
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

      # Decode the data if it has been received through a query. Not if the user set it.
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

      @status = if options.key? :status
        options[:status].to_sym
      else
        nil
      end

      @id = options[:mailing_id] || nil

      if block_given?
        yield self 
        mail
      end
    end


    def address=(value)
      raise ReadOnlyError, :address if created?

      unless value.nil? or value.is_a? String
        raise TypeError, "address must be a String"
      end

      @address = value
    end


    def return_address=(value)
      raise ReadOnlyError, :return_address if created?

      unless value.nil? or value.is_a? String
        raise TypeError, "return_address must be a String" 
      end

      @return_address = value
    end


    def data=(value)
      raise ReadOnlyError, :data if created?

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
        raise TypeError, "bad format for data"
      end
    end


    # Mail the mailing on the server.
    # @return [Stampr::Mailing] self
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

      @status = :received

      self
    end


    # Delete the mailing on the server.
    #
    # @return [nil]
    def delete
      raise APIError, "Can't #delete before #create" unless created?

      id, @id = @id, nil

      Stampr.client.delete ["mailings", id]

      nil
    end

    # Update the value of status from the server.
    def sync
      raise APIError, "can't sync before creation" unless created?

      mailing = Stampr.client.get ["mailings", id]
      @status = mailing["status"].to_sym

      self
    end
  end
end