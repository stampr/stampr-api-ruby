module Stampr
  # Mailing configuration to be used with Batches.
  #
  # TODO: Allow attributes to be set.
  class Config
    DEFAULT_SIZE = :standard
    DEFAULT_TURNAROUND = :threeday
    DEFAULT_STYLE = :color
    DEFAULT_OUTPUT = :single
    DEFAULT_RETURN_ENVELOPE = false

    attr_reader :size, :turnaround, :style, :output, :return_envelope

    class << self
      # Get the config
      # @return [Stampr::Config]
      def [](id)
        raise TypeError, "Expecting positive Integer" unless id.is_a?(Integer) && id > 0

        configs = Stampr.client.get ["configs", id]
        config = configs.first
        self.new Stampr.symbolize_hash_keys(config)       
      end

      def each
        return enum_for(:each) unless block_given?

        i = 0

        loop do
          configs = Stampr.client.get ["configs", "all", i]

          break if configs.empty?

          configs.each do |config|
            yield self.new(Stampr.symbolize_hash_keys(config))
          end   

          i += 1
        end 
      end
    end

    # @option :size [:standard]
    # @option :turnaround [:threeday]
    # @option :style [:color]
    # @option :output [:single]
    # @option :return_envelope [false]
    def initialize(options = {})
      @size = (options[:size] || DEFAULT_SIZE).to_sym
      @turnaround = (options[:turnaround] || DEFAULT_TURNAROUND).to_sym
      @style = (options[:style] || DEFAULT_STYLE).to_sym
      @output = (options[:output] || DEFAULT_OUTPUT).to_sym
      # :returnenvelope is from json, return_envelope is more ruby-friendly for end-users.
      @return_envelope = options[:returnenvelope] || options[:return_envelope] || DEFAULT_RETURN_ENVELOPE
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