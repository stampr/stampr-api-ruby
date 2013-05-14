module Stampr
  class Mailing
    attr_accessor :from, :to, :body

    def initialize(options = {})
      @batch = options[:batch]
      @config = options[:config]

      if block_given?
        yield self 
        send
      end
    end

    def send

    end
  end
end