# frozen_string_literal: true
module Redstruct
  # Simple class holding the Redstruct configuration
  class Configuration
    # @return [ConnectionPool] The Redis-rb connection pool to use
    attr_accessor :connection_pool

    # @return [String] Default namespace for factories
    attr_accessor :namespace

    def initialize
      @connection_pool = nil
      @namespace = nil
    end
  end
end
