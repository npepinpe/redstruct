# frozen_string_literal: true

require 'redstruct/struct'
require 'redstruct/utils/iterable'

module Redstruct
  # Class to manipulate redis hashes, modeled after Ruby's Hash class.
  class Hash < Redstruct::Struct
    include Redstruct::Utils::Iterable

    # Returns the value at key
    # @param [#to_s] key the hash key
    # @return [nil, String] the value at key, or nil if nothing
    def [](key)
      return self.connection.hget(@key, key)
    end

    # Returns the value at key
    # @param [Array<#to_s>] keys a list of keys to fetch; can be only one
    # @return [Hash<String, String>] if only one key was passed, then return the value for it; otherwise returns a Ruby hash
    #                                where each key in the `keys` is mapped to the value returned by redis
    def get(*keys)
      return self.connection.hget(@key, keys.first) if keys.size == 1
      return self.connection.mapped_hmget(@key, *keys).reject { |_, v| v.nil? }
    end

    # Sets or updates the value at key
    # @param [#to_s] key the hash key
    # @param [#to_s] value the new value to set
    # @return [Boolean] true if the field was set (not updated!), false otherwise
    def []=(key, value)
      set(key, value, overwrite: true)
    end

    # Sets or updates the value at key
    # @param [#to_s] key the hash key
    # @param [#to_s] value the new value to set
    # @return [Boolean] true if the field was set (not updated!), false otherwise
    def set(key, value, overwrite: true)
      result = if overwrite
        self.connection.hset(@key, key, value)
      else
        self.connection.hsetnx(@key, key, value)
      end

      return coerce_bool(result)
    end

    # Updates the underlying redis hash using the given Ruby hash's key/value mapping
    # @param [Hash] hash the key/value mapping to use
    # @return [Boolean] true if updated, false otherwise
    def update(hash)
      coerce_bool(self.connection.mapped_hmset(@key, hash))
    end

    # Removes all items for the given keys
    # @param [Array<#to_s>] keys the list of keys to remove
    # @return [Integer] the number of keys removed
    def remove(*keys)
      return self.connection.hdel(@key, keys)
    end

    # Checks if a key has a value
    # @param [#to_s] key the key to check for
    # @return [Boolean] true if the key has a value associated, false otherwise
    def key?(key)
      return coerce_bool(self.connection.hexists(@key, key))
    end

    # Increments the value at the given key
    # @param [#to_s] key the hash key
    # @param [Integer, Float] by defaults to 1
    # @return [Integer, Float] returns the incremented value
    def increment(key, by: 1)
      if by.is_a?(Float)
        self.connection.hincrbyfloat(@key, key, by.to_f).to_f
      else
        self.connection.hincrby(@key, key, by.to_i).to_i
      end
    end

    # Decrements the value at the given key
    # @param [#to_s] key the hash key
    # @param [Integer, Float] by defaults to 1
    # @return [Integer, Float] returns the decremented value
    def decrement(key, by: 1)
      return increment(key, by: -by)
    end

    # @return [Boolean] true if the hash contains no elements
    def empty?
      return !exists?
    end

    # Loads all the hash members in memory
    # NOTE: if the hash is expected to be large, use to_enum
    # @return [Hash<String, String>] all key value pairs stored on redis
    def to_h
      return self.connection.hgetall(@key)
    end

    # @return [Array<String>] a list of all hash keys with values associated
    def keys
      return self.connection.hkeys(@key)
    end

    # @return [Array<Strign>] a list of all hash values
    def values
      return self.connection.hvals(@key)
    end

    # @return [Integer] the number of key value pairs stored for this hash
    def size
      return self.connection.hlen(@key)
    end

    # Use redis-rb hscan_each method to iterate over particular keys
    # @return [Enumerator] base enumerator to iterate of the namespaced keys
    def to_enum(match: '*', count: 10)
      return self.connection.hscan_each(@key, match: match, count: count)
    end
  end
end
