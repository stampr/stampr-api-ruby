module Stampr
  # A batch of Stampr::Mailing
  class Batch
    extend Utilities

    STATUSES = [:processing, :hold, :archive]
    DEFAULT_STATUS = :processing

    attr_reader :config_id, :template, :status

    class << self
      # @overload [](id)
      #   Get the batch with the specific ID.
      #
      #   @param id [Integer] ID of batch to retreive.
      #
      #   @return [Stampr::Mailing]
      #
      # @overload [](time_period, options = {})
      #   Get the batches between two times.
      #
      #   @param time_period [Range<Time/DateTime>] Time period to get mailings for.
      #   @options :status [:processing, :hold, :archive] Status of batch to find.
      #   @return [Array<Stampr::Batch>]
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

          batches = Stampr.client.get ["batches", id]
          self.new symbolize_hash_keys(batches.first)

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

          search = if options.key? :status
            unless options[:status].is_a? Symbol
              raise TypeError, ":status option should be one of #{STATUSES.map(&:inspect).join ", "}" 
            end

            unless STATUSES.include? options[:status]
              raise ArgumentError, ":status option should be one of #{STATUSES.map(&:inspect).join ", "}" 
            end

            ["with", options[:status]]      
          else
            ["browse"]   
          end

          all_batches = []
          i = 0

          loop do
            batches = Stampr.client.get ["batches", *search,
                from.to_time.utc.iso8601, to.to_time.utc.iso8601, i]

            break if batches.empty?

            all_batches.concat batches.map {|m| self.new symbolize_hash_keys(m) }

            i += 1
          end

          all_batches

        else
          raise TypeError, "index must be a positive Integer or Time/DateTime range"
        end     
      end
    end


    # If neither :config_id or :config options are provided, then a new, default, config will be applied to this batch.
    #
    # @option options :config_id [Integer] ID of the config to use.
    # @option options :config [Stampr::Config] Config to use.
    # @option options :template [String]
    # @option options :status [:processing, :hold] The initial status of the mailing (:processing)
    def initialize(options={})
      raise ArgumentError, "Must supply :config_id OR :config options" if options.key?(:config_id) && options.key?(:config)

      @config_id = if options.key? :config_id
        raise TypeError, ":config_id option must be an Integer" unless options[:config_id].is_a? Integer
        options[:config_id]

      elsif options.key? :config
        raise TypeError, ":config option must be an Stampr::Config" unless options[:config].is_a? Stampr::Config
        options[:config].id

      else
        @config = Config.new
        @config.id
      end

      @id = options[:batch_id] || nil
      self.template = options[:template]
      self.status = (options[:status] || DEFAULT_STATUS).to_sym

      yield self if block_given?
    end


    def template=(value)
      raise TypeError, "template must be a String" unless value.nil? || value.is_a?(String)

      @template = value
    end


    # One of:
    # * :processing
    # * :hold
    # * :archive
    #
    # @return [:processing, :hold, :archive]
    def status=(value)
      raise TypeError, "status must be a Symbol" unless value.is_a? Symbol
      raise ArgumentError, "status must be one of: #{STATUSES.map(&:inspect).join(", ")}" unless STATUSES.include? value

      @status = value
    end

    # Get the id of the batch. Calling this will create the batch first, if required.
    #
    # @return [Integer]
    def id
      create unless @id
      @id
    end


    # Create the config on the server.
    #
    # @return [Stampr::Config]
    def create
      return if @id # Don't re-create if it already exists.

      params = {
          config_id: config_id,
          status: status,
      }

      params[:template] = template if template
      result = Stampr.client.post "batches", params
                                  
      @id = result["batch_id"]

      self
    end


    # Delete the config on the server (this will fail if there are mailings still inside the batch).
    #
    # @return true on successful deletion.
    def delete
      raise APIError, "Can't #delete before #create" unless @id

      id, @id = @id, nil

      Stampr.client.delete ["batches", id]

      true
    end


    # Create a Mailing for this Batch.
    #
    # @yield [Stampr::Mailing] The mailing created.
    def mailing(&block)
      Mailing.new batch: self, &block
    end
  end
end