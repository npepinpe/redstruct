module Restruct
  # Entry point to create other Redis data structures
  class Factory
    include Restruct::Utils::Inspectable

    # @return [Restruct::Connection] The connection proxy to use when executing commands. Shared by all factory produced objects.
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
      return Restruct::Types::Lock.new(factory: factory(key), **options)
    end

    def counter(key)
      return create(Restruct::Types::Counter, key)
    end

    def script(script)
      return Restruct::Types::Script.new(script: script, factory: self)
    end

    def factory(namespace)
      return self.class.new(connection: @connection, namespace: isolate(namespace))
    end

    def create(type, key)
      return type.new(key: isolate(key), factory: self)
    end
    private :create

    def isolate(key)
      return (@namespace.nil? || key.start_with?(@namespace)) ? key : "#{@namespace}:#{key}"
    end
    private :isolate

    # :nocov:
    def inspectable_attributes
      return { namespace: @namespace, connection: @connection }
    end
    # :nocov:
  end
end
