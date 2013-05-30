module Stampr
  # Mailing configuration to be used with Batches.
  #
  # TODO: Allow attributes to be set.
  class Config
    extend Utilities

    DEFAULT_SIZE = :standard
    DEFAULT_TURNAROUND = :threeday
    DEFAULT_STYLE = :color
    DEFAULT_OUTPUT = :single
    DEFAULT_RETURN_ENVELOPE = false

    attr_reader :size, :turnaround, :style, :output, :return_envelope

    class << self
      # Get the config with a specific id.
      #
      # @return [Stampr::Config]
      def [](id)
        raise TypeError, "Expecting positive Integer" unless id.is_a?(Integer) && id > 0

        configs = Stampr.client.get ["configs", id]
        config = configs.first
        self.new symbolize_hash_keys(config)       
      end

      # Get a list of all configs defined in your Stampr account.
      #
      # @return [Array<Stampr::Config>]
      def all
        all_configs = []
        i = 0

        loop do
          configs = Stampr.client.get ["configs", "all", i]
          break if configs.empty?

          all_configs.concat configs.map {|c| self.new symbolize_hash_keys(c) }

          i += 1
        end 

        all_configs
      end
    end

    # @option options :size [:standard]
    # @option options :turnaround [:threeday]
    # @option options :style [:color]
    # @option options :output [:single]
    # @option options :return_envelope [false]
    def initialize(options = {})
      @size = (options[:size] || DEFAULT_SIZE).to_sym
      @turnaround = (options[:turnaround] || DEFAULT_TURNAROUND).to_sym
      @style = (options[:style] || DEFAULT_STYLE).to_sym
      @output = (options[:output] || DEFAULT_OUTPUT).to_sym
      # :returnenvelope is from json, return_envelope is more ruby-friendly for end-users.
      @return_envelope = options[:returnenvelope] || options[:return_envelope] || DEFAULT_RETURN_ENVELOPE
      @id = options[:config_id] || nil

      yield self if block_given?
    end


    # Get the id of the configuration. Calling this will create the config first, if required.
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

      result = Stampr.client.post "configs",
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