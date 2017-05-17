# frozen_string_literal: true

require 'redis'
require 'connection_pool'
require 'redstruct/utils/inspectable'
require 'redstruct/error'

module Redstruct
  # Connection proxy class for the ConnectionPool
  class ConnectionProxy
    include Redstruct::Utils::Inspectable

    # @return [Array<Symbol>] List of methods from the Redis class that we don't want to proxy
    NON_COMMAND_METHODS = %i[[] []= _eval _scan method_missing call dup inspect to_s].freeze

    # @param [Redis, ConnectionPool<Redis>] pool_or_conn a redis connection, or a pool of redis connections
    # @raise [ArgumentError] raises an exception if the argument is not one of the required classes
    def initialize(pool_or_conn)
      case pool_or_conn
      when ConnectionPool
        @pool = pool_or_conn
      when Redis
        @redis = pool_or_conn
      else
        raise(ArgumentError, 'requires an instance of ConnectionPool or Redis to proxy to')
      end
    end

    # Executes the given block by first fixing a thread local connection from the pool,
    # such that all redis commands executed within the block are on the same connection.
    # This is necessary when doing pipelining, or multi/exec stuff
    # @yield [Redis] a direct redis connection
    # @return [Object] whatever the passed block evaluates to, nil otherwise
    def with(&_block)
      unless block_given?
        Redstruct.logger.warn('do not Redstruct::ConnectionProxy#with with no block')
        return
      end

      connection = @redis || Thread.current[:__redstruct_connection]
      result = if connection.nil?
        @pool.with do |c|
          begin
            Thread.current[:__redstruct_connection] = c
            yield(c)
          ensure
            Thread.current[:__redstruct_connection] = nil
          end
        end
      else
        yield(connection)
      end

      return result
    end

    # While slower on load, defining all methods that we want to pipe to one of the connections results in
    # faster calls at runtime, and gives us the convenience of not going through the pool.with everytime.
    Redis.public_instance_methods(false).each do |method|
      next if NON_COMMAND_METHODS.include?(method) || method_defined?(method)
      class_eval <<~METHOD, __FILE__, __LINE__ + 1
        # Proxy method for Redis##{method} to work with a connection pool
        # Uses Redstruct::ConnectionProxy#with to obtain a connection (or the connection) and executes the method on it
        def #{method}(*args, &block)
          with { |c| c.#{method}(*args, &block) }
        end
      METHOD
    end

    # @!group redis-rb polyfills
    # The following methods are methods not currently implemented in redis-rb,
    # or only in trunk; they should be remove once support is wide-spread

    # see: https://redis.io/commands/zlexcount
    # zlexcount is not supported as of redis-rb 3.3.2
    def zlexcount(key, min, max)
      with do |c|
        c.synchronize do |client|
          client.call([:zlexcount, key, min, max])
        end
      end
    end

    # @!endgroup

    # Necessary when overwriting method_missing, so that respond_to? work properly
    # @param [String, Symbol] _method the method name
    # @param [Boolean] _include_private if true, also looks up private methods
    # @return [Boolean] true if responding through method_missing, false otherwise
    def respond_to_missing?(_method, _include_private = false)
      true
    end
    private :respond_to_missing?

    # Fallback when calling methods we may not have dynamically created above
    # @param [String, Symbol] method the called method name
    # @param [Array<Object>] args the arguments it was called with
    # @param [Proc] block optionally, the block it was called with
    # @return [Object] whatever the method returns
    def method_missing(method, *args, &block)
      with do |c|
        if c.respond_to?(method)
          c.public_send(method, *args, &block)
        else
          super
        end
      end
    end

    # @!visibility private
    def inspectable_attributes # :nodoc:
      transport = if !@pool.nil?
        'connection_pool'
      elsif !@redis.nil?
        'redis'
      else
        'nothing'
      end

      return { transport: transport }
    end
  end
end
