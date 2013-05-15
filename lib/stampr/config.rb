module Stampr
  # Mailing configuration to be used with Batches.
  #
  # TODO: Allow attributes to be set.
  class Config
    attr_reader :client
    attr_reader :size, :turnaround, :style, :output, :return_envelope

    # @param client [Stampr::Client]
    def initialize(client, options={})
      raise TypeError, "client must be a Stampr::Client" unless client.is_a? Stampr::Client

      # Convert data hash to use symbols, since it may be being set from json data.
      options = Hash[options.map {|k, v| [k.to_sym, v.is_a?(String) ? v.to_sym : v]}]

      @client = client
      @size = options[:size] || :standard
      @turnaround = options[:turnaround] || :threeday
      @style = options[:style] || :color
      @output = options[:output] || :single
      @return_envelope = options[:returnenvelope] || options[:return_envelope] || false
      @id = options[:config_id] || nil
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

      result = @client.post "configs",
                            size: size,
                            turnaround: turnaround, 
                            style: style,
                            output: output,
                            returnenvelope: return_envelope

      @id = result["config_id"]

      self
    end
  end
end