# frozen_string_literal: true
module Redstruct
  # Main interface of the gem; this class should be used to build all Redstruct
  # objects, even when deserializing them.
  class Factory
    include Redstruct::Utils::Inspectable, Redstruct::Factory::Creation
    extend Redstruct::Factory::Deserialization

    # @return [Connection] The connection proxy to use when executing commands. Shared by all factory produced objects.
    attr_reader :connection

    # @param [Redstruct::Connection] connection connection to use for all objects built by the factory
    # @param [ConnectionPool] pool pool to use to build a connection from if no connection param given
    # @param [::String] namespace all objects build from the factory will have their keys namespaced under this one
    # @return [Factory]
    def initialize(connection: nil, pool: nil, namespace: nil)
      namespace ||= Redstruct.config.namespace

      if connection.nil?
        pool ||= Redstruct.config.connection_pool
        raise(Redstruct::Error, 'A connection pool is required to create a factory, but none was given') if pool.nil?
        connection = Redstruct::Connection.new(pool)
      end

      @connection = connection
      @namespace = namespace
      @script_cache = {}.tap { |hash| hash.extend(MonitorMixin) }
    end

    # Returns a namespaced version of the key (unless already namespaced)
    # @param [String] key the key to isolate/namespace
    # @return [String] namespaced version of the key (or the key itself if already namespaced)
    def isolate(key)
      return @namespace.nil? || key.start_with?(@namespace) ? key : "#{@namespace}:#{key}"
    end

    # Iterates over the keys of this factory using the Redis scan command
    # For more about the scan command, see https://redis.io/commands/scan
    # @param [String] match will prepend the factory namespace to the match string; see the redis documentation for the syntax
    # @param [Integer] count maximum number of items returned per iteration
    # @param [Integer] max maximum number of iterations; if none given, could potentially never terminate
    # @return [Enumerator::Lazy] if no block given, returns an enumerator that you can chain with others
    def each(match: '*', count: nil, max: 10_000, &block)
      options = { match: isolate(match) }
      options[:count] = count.to_i unless count.nil?

      enumerator = @connection.scan_each(options)
      enumerator = enumerator.each_slice(count) unless count.nil?

      # creates a temporary enumerator which limits the number of possible iterations, ensuring this eventually finishes
      unless max.nil?
        unbounded_enumerator = enumerator
        enumerator = Enumerator.new do |yielder|
          iterations = 0
          loop do
            yielder << unbounded_enumerator.next
            iterations += 1
            raise StopIteration if iterations == max
          end
        end
      end

      return enumerator unless block_given?
      return enumerator.each(&block)
    end

    # Deletes all keys created by the factory. By defaults will iterate at most of 500 million keys
    # @param [Hash] options accepts the options as given in each
    # @see Redstruct::Factory#each
    def delete_all(options = {})
      return each({ match: '*', count: 500, max: 1_000_000 }.merge(options)) do |keys|
        @connection.del(*keys)
      end
    end

    # :nocov:

    # Helper method for serialization
    def inspectable_attributes
      return { namespace: @namespace, script_cache: @script_cache.keys }
    end

    # :nocov:
  end
end
