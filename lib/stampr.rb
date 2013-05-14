require "rest_client"
require "json"

require_relative "stampr/client"
require_relative "stampr/batch"
require_relative "stampr/config"
require_relative "stampr/mailing"
require_relative "stampr/version"

module Stampr
  class HTTPError < StandardException; end
end
