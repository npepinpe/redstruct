# frozen_string_literal: true
module Redstruct
  # Simple class holding the Redstruct configuration
  class Configuration
    # @return [ConnectionPool, Redis] the default redis-rb connection, or a pool of said connections
    attr_accessor :default_connection

    # @return [String] Default namespace for factories
    attr_accessor :default_namespace

    def initialize
      @default_connection = nil
      @default_namespace = nil
    end
  end
end
