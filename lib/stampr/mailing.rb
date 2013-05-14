module Stampr
  class Mailing
    attr_accessor :from, :to, :body

    def initialize(options = {})
      @batch = options[:batch] || Batch.new

      if block_given?
        yield self 
        send
      end
    end

    def send

    end
  end
end