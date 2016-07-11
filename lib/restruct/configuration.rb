module Restruct
  class Configuration
    # @return [ConnectionPool] The Redis-rb connection pool to use
    attr_accessor :connection_pool

    def initialize
      @connection_pool = nil
    end
  end
end
