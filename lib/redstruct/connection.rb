module Redstruct
  class Connection
    # @return [Array<Symbol>] List of methods from the Redis class that we don't want to delegate to.
    NON_COMMAND_METHODS = [:[], :[]=, :_eval, :_scan, :method_missing, :call, :dup, :inspect, :to_s].freeze

    attr_reader :pool

    def initialize(pool)
      raise(Redstruct::Error, 'Requires a ConnectionPool to proxy to') unless pool.is_a?(ConnectionPool)
      @pool = pool
    end

    # Executes the given block by first fixing a thread local connection from the pool,
    # such that all redis commands executed within the block are on the same connection.
    # This is necessary when doing pipelining, or multi/exec stuff
    # @return [Object] whatever the passed block evaluates to, nil otherwise
    def with
      result = nil
      @pool.with do |c|
        begin
          Thread.current[:__redstruct_connection] = c
          result = yield(c) if block_given?
        ensure
          Thread.current[:__redstruct_connection] = nil
        end
      end

      return result
    end

    # While slower on load, defining all methods that we want to pipe to one of the connections results in
    # faster calls at runtime, and gives us the convenience of not going through the pool.with everytime.
    Redis.public_instance_methods(false).each do |method|
      next if NON_COMMAND_METHODS.include?(method)
      class_eval <<~METHOD, __FILE__, __LINE__ + 1
        def #{method}(*args, &block)
          connection = Thread.current[:__redstruct_connection]
          if connection.nil?
            with { |c| c.#{method}(*args, &block) }
          else
            return connection.#{method}(*args, &block)
          end
        end
      METHOD
    end
  end
end
