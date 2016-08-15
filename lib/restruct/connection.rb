module Restruct
  class Connection
    # @return [Array<Symbols>] List of methods from the Redis class that we don't want to delegate to.
    NON_COMMAND_METHODS = [:[], :[]=, :_eval, :_scan, :method_missing, :call, :dup, :inspect, :to_s].freeze

    def initialize(pool)
      raise(Restruct::Error, 'Requires a ConnectionPool to proxy to') unless pool.is_a?(ConnectionPool)
      @pool = pool
    end

    # While slower on load, defining all methods that we want to pipe to one of the connections results in
    # faster calls at runtime, and gives us the convenience of not going through the pool.with everytime.
    Redis.public_instance_methods(false).each do |method|
      next if NON_COMMAND_METHODS.include?(method)
      class_eval <<~METHOD, __FILE__, __LINE__ + 1
        def #{method}(*args)
          return @pool.with { |c| c.#{method}(*args) }
        end
      METHOD
    end
  end
end