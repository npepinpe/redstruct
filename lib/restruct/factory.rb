module Restruct
  # Entry point to create other Redis data structures
  class Factory
    def initialize(pool: nil, namespace: nil)
      pool ||= Restruct.config.connection_pool
      namespace ||= Restruct.config.namespace

      raise(Restruct::Error, 'A connection pool is required to create a factory, but none was given') if pool.nil?

      @pool = pool
      @namespace = namespace
    end

    def struct(key)
      return create(Restruct::Struct, key)
    end

    def string(key)
      return create(Restruct::String, key)
    end

    def list(key)
      return create(Restruct::List, key)
    end

    def set(key)
      return create(Restruct::Set, key)
    end

    def sorted_set(key)
      return create(Restruct::SortedSet, key)
    end

    def hash(key)
      return create(Restruct::Hash, key)
    end

    def lock(key)
      return create(Restruct::Lock, key)
    end

    def counter(key)
      return create(Restruct::Counter, key)
    end

    def create(type, key)
      return type.new(isolate(key), pool: @pool)
    end
    private :create

    def isolate(key)
      return (@namespace.nil? || key.start_with?(@namespace)) ? key : "#{@namespace}:#{key}"
    end
    private :isolate
  end
end
