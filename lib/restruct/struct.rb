module Restruct
  class Struct
    # @param [String] Key/identifier on the server
    # @param [ConnectionPool] Connection pool to use to execute commands
    def initialize(key:, pool:)
      @key = key
      @pool = pool
    end

    def exists?
      success = false
      @pool.with { |c| exists = c.exists(@key) }
      return success
    end

    def delete
      @pool.with { |c| c.delete(@key) }
    end

    def expire(ttl)
      success = false
      @pool.with { |c| success = c.expire(@key, ttl) }
      return success
    end

    def expire_at(time)
      success = false
      @pool.with { |c| success = c.expire_at(@key,  time.to_i) }
      return success
    end

    def persist
      success = false
      @pool.with { |c| success = c.persist(@key) }
      return success
    end
  end
end
