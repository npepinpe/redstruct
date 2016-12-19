module Redstruct
  class Factory
    # Module to hold all the factory creation methods.
    module Creation
      # Builds a struct with the given key (namespaced) and sharing the factory connection
      # Building a struct is only really useful if you plan on making only basic operations,
      # such as delete, expire, etc. It is however recommended to always build your objects
      # in the same way, e.g. if it's a lock, use Factory#lock
      # @param [::String] key base key to use
      # @return [Redstruct::Types::Struct] base struct pointing to that key
      def struct(key, **options)
        return create(Redstruct::Types::Struct, key, **options)
      end

      # Builds a Redis string struct from the key
      # @param [::String] key base key to use
      # @return [Redstruct::Types::String]
      def string(key, **options)
        return create(Redstruct::Types::String, key, **options)
      end

      # Builds a Redis list struct from the key
      # @param [::String] key base key to use
      # @return [Redstruct::Types::List]
      def list(key, **options)
        return create(Redstruct::Types::List, key, **options)
      end

      # Builds a Redis set struct from the key
      # @param [::String] key base key to use
      # @return [Redstruct::Types::Set]
      def set(key, **options)
        return create(Redstruct::Types::Set, key, **options)
      end

      # Builds a Redis sorted set (zset) struct from the key
      # @param [::String] key base key to use
      # @return [Redstruct::Types::SortedSet]
      def sorted_set(key, **options)
        return create(Redstruct::Types::SortedSet, key, **options)
      end

      # Builds a Redis hash struct from the key
      # @param [::String] key base key to use
      # @return [Redstruct::Types::Hash]
      def hash(key, **options)
        return create(Redstruct::Types::Hash, key, **options)
      end

      # Builds a Redis backed lock from the key
      # @param [::String] key base key to use
      # @return [Redstruct::Hls::Lock]
      def lock(key, **options)
        return create(Redstruct::Hls::Lock, key, **options)
      end

      # Builds a Redis counter struct from the key
      # @param [::String] key base key to use
      # @return [Redstruct::Types::Counter]
      def counter(key, **options)
        return create(Redstruct::Types::Counter, key, **options)
      end

      # Builds a Redis backed queue from the key
      # @param [::String] key base key to use
      # @return [Redstruct::Hls::Queue]
      def queue(key)
        return create(Redstruct::Hls::Queue, key)
      end

      # Returns a factory with an isolated namespace.
      # @example Given a factory `f` with namespace fact:first
      #   f.factory('second') # => Redstruct::Factory: namespace: <"fact:first:second">, script_cache: <[]>
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
