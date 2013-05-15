module Stampr
  class Batch
    STATUSES = [:processing, :hold]

    attr_reader :id, :config_id, :template, :status

    # @option :config_id [Integer]
    # @option :config [Stampr::Config]
    # @option :template [String]
    # @option :status [:processing or :hold]
    def initialize(options={})
      @config_id = if options[:config_id]
        options[:config_id]
      elsif options[:config]
        options[:config].id
      else
        raise ArgumentError, "config or config_id options required"
      end

      @id = options[:batch_id] || nil
      self.template = options[:template]
      self.status = (options[:status] || :processing).to_sym

      raise TypeError, "config_id must be an Integer" unless @config_id.is_a? Integer
    end


    def template=(value)
      raise TypeError, "template must be a String" unless value.nil? || value.is_a?(String)

      @template = value
    end


    def status=(value)
      raise ArgumentError, "status must be one of: #{STATUSES.join(", ")}" unless STATUSES.include? value

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