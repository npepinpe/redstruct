module Restruct
  class Factory
    # Module to hold all the factory creation methods.
    module Creation
      # Builds a struct with the given key (namespaced) and sharing the factory connection
      # Building a struct is only really useful if you plan on making only basic operations,
      # such as delete, expire, etc. It is however recommended to always build your objects
      # in the same way, e.g. if it's a lock, use Factory#lock
      # @param [::String] key base key to use
      # @return [Restruct::Types::Struct] base struct pointing to that key
      def struct(key)
        return create(Restruct::Types::Struct, key)
      end

      # Builds a Redis string struct from the key
      # @param [::String] key base key to use
      # @return [Restruct::Types::String]
      def string(key)
        return create(Restruct::Types::String, key)
      end

      # Builds a Redis list struct from the key
      # @param [::String] key base key to use
      # @return [Restruct::Types::List]
      def list(key)
        return create(Restruct::Types::List, key)
      end

      # Builds a Redis set struct from the key
      # @param [::String] key base key to use
      # @return [Restruct::Types::Set]
      def set(key)
        return create(Restruct::Types::Set, key)
      end

      # Builds a Redis sorted set (zset) struct from the key
      # @param [::String] key base key to use
      # @return [Restruct::Types::SortedSet]
      def sorted_set(key)
        return create(Restruct::Types::SortedSet, key)
      end

      # Builds a Redis hash struct from the key
      # @param [::String] key base key to use
      # @return [Restruct::Types::Hash]
      def hash(key)
        return create(Restruct::Types::Hash, key)
      end

      # Builds a Redis backed lock from the key
      # @param [::String] key base key to use
      # @return [Restruct::Types::Lock]
      def lock(key, **options)
        return create(Restruct::Types::Lock, key, **options)
      end

      # Builds a Redis counter struct from the key, which is actually based on a
      # Restruct::Types::String
      # @param [::String] key base key to use
      # @return [Restruct::Types::Counter]
      def counter(key)
        return create(Restruct::Types::Counter, key)
      end

      # Builds a Redis backed queue from the key
      # @param [::String] key base key to use
      # @return [Restruct::Types::Queue]
      def queue(key)
        return create(Restruct::Types::Queue, key)
      end

      # @todo The script cache is actually based on the database you will connect to. Therefore, it might be smarter to move it to the connection used?
      # Caveat: if the script with the given ID exists in the cache, we don't bother updating it.
      # So if the script actually changed since the first call, the one sent during the first call will
      def script(id, script)
        return @script_cache.synchronize do
          @script_cache[id] = Restruct::Types::Script.new(key: id, script: script, factory: self) if @script_cache[id].nil?
          @script_cache[id]
        end
      end

      # Returns a factory with an isolated namespace.
      # @example Given a factory `f` with namespace fact:first
      #   f.factory('second') # => Restruct::Factory: namespace: <"fact:first:second">, script_cache: <[]>
      # @return [Factory] namespaced factory
      def factory(namespace)
        return self.class.new(connection: @connection, namespace: isolate(namespace))
      end

      def create(type, key, **options)
        return type.new(key: isolate(key), factory: self, **options)
      end
      private :create
    end
  end
end
