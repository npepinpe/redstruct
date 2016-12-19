# frozen_string_literal: true
require 'redstruct/types/struct'
require 'redstruct/utils/coercion'

module Redstruct
  module Types
    class Hash < Redstruct::Types::Struct
      def [](key)
        return self.connection.hget(@key, key)
      end

      def []=(key, value)
        self.connection.hset(@key, key, value)
      end

      def set(key, value, overwrite: true)
        if overwrite
          self[key] = value
        else
          self.connection.hsetnx(@key, key, value)
        end
      end

      def get(*keys)
        return self[keys.first] if keys.size == 1
        return self.connection.mapped_hmget(@key, *keys)
      end

      def update(hash)
        self.connection.mapped_hmset(@key, hash)
      end

      def remove(*keys)
        return self.connection.hdel(@key, keys)
      end

      def key?(key)
        return coerce_bool(self.connection.hexists(@key, key))
      end

      def incr(key, increment: 1)
        if increment.is_a?(Float)
          self.connection.hincrbyfloat(@key, key, increment.to_f)
        else
          self.connection.hincrby(@key, key, increment)
        end
      end

      def decr(key, increment: 1)
        return incr(key, -increment)
      end

      def to_h
        return self.connection.hgetall(@key)
      end

      def keys
        return self.connection.hkeys(@key)
      end

      def values
        return self.connection.hvals(@key)
      end

      def size
        return self.connection.hlen(@key)
      end

      def each(options = {}, &block)
        return self.connection.hscan_each(@key, options, &block)
      end
    end
  end
end
