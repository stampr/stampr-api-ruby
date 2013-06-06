module Stampr
  # General utility methods to be used inside the gem.
  module Utilities
    private
    # Symbolize all the keys in a Hash.
    #
    # @param hash [Hash] Hash with String keys.
    # @return [Hash] Equivalent Hash with Symbolic keys.
    def symbolize_hash_keys(hash)
      Hash[hash.map {|k, v| [k.to_sym, v]}]
    end
  end
end