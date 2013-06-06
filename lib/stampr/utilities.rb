module Stampr
  # General utility methods to be used inside the gem.
  module Utilities
    class << self
      def included(base)
        base.extend self
      end
    end

    private
    # Symbolize all the keys in a Hash.
    #
    # @param hash [Hash] Hash with String keys.
    # @return [Hash] Equivalent Hash with Symbolic keys.
    def symbolize_hash_keys(hash)
      Hash[hash.map {|k, v| [k.to_sym, v]}]
    end

    private
    # List of values for error message
    def bad_attribute(attribute, values)
      "#{attribute} must be one of #{values.map(&:inspect).join(", ")}"
    end
  end
end