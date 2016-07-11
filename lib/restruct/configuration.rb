module Restruct
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
