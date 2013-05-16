module Stampr
  class Batch
    STATUSES = [:processing, :hold, :archive]
    DEFAULT_STATUS = :processing

    attr_reader :id, :config_id, :template, :status

    class << self
      # Get the batch with the specific ID.
      # @return [Stampr::Config]
      def [](id)
        raise TypeError, "id should be a positive Integer" unless id.is_a?(Integer) && id > 0

        batches = Stampr.client.get ["batches", id]
        batch = batches.first
        self.new Stampr.symbolize_hash_keys(batch)       
      end
    end


    # @option :config_id [Integer]
    # @option :config [Stampr::Config]
    # @option :template [String]
    # @option :status [:processing or :hold]
    def initialize(options={})
      @config_id = if options[:config_id] and not options[:config]
        raise TypeError, ":config_id option must be an Integer" unless options[:config_id].is_a? Integer
        options[:config_id]

      elsif options[:config]
        raise TypeError, ":config option must be an Stampr::Config" unless options[:config].is_a? Stampr::Config
        options[:config].id

      else
        raise ArgumentError, "Must supply :config_id OR :config options"
      end

      @id = options[:batch_id] || nil
      self.template = options[:template]
      self.status = (options[:status] || DEFAULT_STATUS).to_sym
    end


    def template=(value)
      raise TypeError, "template must be a String" unless value.nil? || value.is_a?(String)

      @template = value
    end


    def status=(value)
      raise TypeError, "status must be a Symbol" unless value.is_a? Symbol
      raise ArgumentError, "status must be one of: #{STATUSES.map(&:inspect).join(", ")}" unless STATUSES.include? value

      @status = value
    end


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


    # @return true on successful deletion.
    def delete
      raise APIError, "Can't #delete before #create" unless @id

      id, @id = @id, nil

      Stampr.client.delete ["batches", id]

      true
    end
  end
end