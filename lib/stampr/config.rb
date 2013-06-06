module Stampr
  # Mailing configuration to be used with Batches.
  #
  # @!attribute [rw] size
  #   @return [:standard] The ID of the config associated with the mailing.
  #
  # @!attribute [rw] style 
  #   @return [:color] Style of printing.
  #
  # @!attribute [rw] turnaround 
  #   @return [:threeday] Time for turnaround of post.
  #
  # @!attribute [rw] output
  #   @return [:single] Type of output printing.
  #
  # @!attribute [rw] return_envelope
  #   @return [false] Whether to include a return envelope
  class Config
    include Utilities

    SIZES = [:standard]
    DEFAULT_SIZE = :standard

    TURNAROUNDS = [:threeday]
    DEFAULT_TURNAROUND = :threeday

    STYLES = [:color]
    DEFAULT_STYLE = :color

    OUTPUTS = [:single]
    DEFAULT_OUTPUT = :single

    RETURN_ENVELOPES = [true, false]
    DEFAULT_RETURN_ENVELOPE = false

    attr_reader :size, :turnaround, :style, :output, :return_envelope

    class << self
      # Get the config with a specific id.
      #
      # @example
      #   config = Stampr::Config[123123]
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
      # @example
      #   configs = Stampr::Config.all
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

    # Has the Config been created already?
    def created?; !@id.nil?; end

    # @option options :size [:standard]
    # @option options :turnaround [:threeday]
    # @option options :style [:color]
    # @option options :output [:single]
    # @option options :return_envelope [false]
    def initialize(options = {})
      self.size = (options[:size] || DEFAULT_SIZE).to_sym
      self.turnaround = (options[:turnaround] || DEFAULT_TURNAROUND).to_sym
      self.style = (options[:style] || DEFAULT_STYLE).to_sym
      self.output = (options[:output] || DEFAULT_OUTPUT).to_sym

      # :returnenvelope is from json, return_envelope is more ruby-friendly for end-users.
      self.return_envelope = options[:returnenvelope] || options[:return_envelope] || DEFAULT_RETURN_ENVELOPE

      @id = options[:config_id] || nil

      yield self if block_given?
    end


    def size=(value)
      raise ReadOnlyError, :size if created?
      raise TypeError, bad_attribute(:size, SIZES) unless value.is_a? Symbol
      raise ArgumentError, bad_attribute(:size, SIZES) unless SIZES.include? value

      @size = value
    end


    def turnaround=(value)
      raise ReadOnlyError, :turnaround if created?
      raise TypeError, bad_attribute(:turnaround, TURNAROUNDS) unless value.is_a? Symbol
      raise ArgumentError, bad_attribute(:turnaround, TURNAROUNDS) unless TURNAROUNDS.include? value

      @turnaround = value
    end


    def style=(value)
      raise ReadOnlyError, :style if created?
      raise TypeError, bad_attribute(:style, STYLES) unless value.is_a? Symbol
      raise ArgumentError, bad_attribute(:style, STYLES) unless STYLES.include? value

      @style = value
    end


    def output=(value)
      raise ReadOnlyError, :output if created?
      raise TypeError, bad_attribute(:output, OUTPUTS) unless value.is_a? Symbol
      raise ArgumentError, bad_attribute(:output, OUTPUTS) unless OUTPUTS.include? value

      @output = value
    end


    def return_envelope=(value)
      raise ReadOnlyError, :return_envelope if created?#
      raise TypeError, bad_attribute(:return_envelope, RETURN_ENVELOPES) unless RETURN_ENVELOPES.include? value

      @return_envelope = value
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