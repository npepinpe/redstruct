module Restruct
  # Entry point to create other Redis data structures
  class Factory
    include Restruct::Utils::Inspectable

    # @return [Connection] The connection proxy to use when executing commands. Shared by all factory produced objects.
    attr_reader :connection

    def initialize(connection: nil, pool: nil, namespace: nil)
      namespace ||= Restruct.config.namespace

      if connection.nil?
        pool ||= Restruct.config.connection_pool
        raise(Restruct::Error, 'A connection pool is required to create a factory, but none was given') if pool.nil?
        connection = Restruct::Connection.new(pool)
      end

      @connection = connection
      @namespace = namespace
      @script_cache = {}.tap { |hash| hash.extend(MonitorMixin) }
    end

    def struct(key)
      return create(Restruct::Types::Struct, key)
    end

    def string(key)
      return create(Restruct::Types::String, key)
    end

    def list(key)
      return create(Restruct::Types::List, key)
    end

    def set(key)
      return create(Restruct::Types::Set, key)
    end

    def sorted_set(key)
      return create(Restruct::Types::SortedSet, key)
    end

    def hash(key)
      return create(Restruct::Types::Hash, key)
    end

    def lock(key, **options)
      return create(Restruct::Types::Lock, key, **options)
    end

    def counter(key)
      return create(Restruct::Types::Counter, key)
    end

    def queue(key)
      return create(Restruct::Types::Queue, key)
    end

    # Caveat: if the script with the given ID exists in the cache, we don't bother updating it.
    # So if the script actually changed since the first call, the one sent during the first call will
    def script(id, script)
      return @script_cache.synchronize do
        @script_cache[id] = Restruct::Types::Script.new(key: id, script: script, factory: self) if @script_cache[id].nil?
        @script_cache[id]
      end
    end

    def factory(namespace)
      return self.class.new(connection: @connection, namespace: isolate(namespace))
    end

    def create(type, key, **options)
      return type.new(key: isolate(key), factory: self, **options)
    end
    private :create

    def isolate(key)
      return (@namespace.nil? || key.start_with?(@namespace)) ? key : "#{@namespace}:#{key}"
    end

    # :nocov:
    def inspectable_attributes
      return { namespace: @namespace, script_cache: @script_cache.keys }
    end
    # :nocov:
  end
end
