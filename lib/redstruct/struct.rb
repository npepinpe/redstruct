# frozen_string_literal: true

require 'redstruct/factory/object'
require 'redstruct/utils/coercion'

module Redstruct
  # Base class for all redis structures which have a particular value for a given key
  class Struct < Redstruct::Factory::Object
    include Redstruct::Utils::Coercion

    # @return [String] the key used to identify the struct on redis
    attr_reader :key

    # @param [String] key the key used to identify the struct on redis, already namespaced
    def initialize(key:, **options)
      super(**options)
      @key = key
    end

    # @return [Boolean] Returns true if it exists in redis, false otherwise
    def exists?
      return self.connection.exists(@key)
    end

    # @return [Boolean] false if nothing was deleted in the DB, true if it was
    def delete
      return coerce_bool(self.connection.del(@key))
    end

    # Sets the key to expire after ttl seconds
    # @param [#to_f] ttl the time to live in seconds (where 0.001 = 1ms)
    # @return [Boolean] true if expired, false otherwise
    def expire(ttl)
      ttl = (ttl.to_f * 1000).floor
      return coerce_bool(self.connection.pexpire(@key, ttl))
    end

    # Sets the key to expire at the given timestamp.
    # @param [#to_f] time time or unix timestamp at which the key should expire; once converted to float, assumes 1.0 is one second, 0.001 is 1 ms
    # @return [Boolean] true if expired, false otherwise
    def expire_at(time)
      time = (time.to_f * 1000).floor
      return coerce_bool(self.connection.pexpireat(@key, time))
    end

    # Removes the expiry time from a key
    # @return [Boolean] true if persisted, false otherwise
    def persist
      coerce_bool(self.connection.persist(@key))
    end

    # @return [String] the underlying redis type
    def type
      self.connection.type(@key)
    end

    # Returns the time to live of the key
    # @return [Float] time to live in seconds as a float where 0.001 == 1 ms
    def ttl
      return self.connection.pttl(@key) / 1000.0
    end

    # Returns a serialized representation of the key, which can be used to store a value externally, and restored to
    # redis using #restore
    # NOTE: This does not capture the TTL of the struct. If there arises a need for this, we can always modify it,
    # but for now this is a pure proxy of the redis dump command
    # @return [String, nil] nil if the struct does not exist, otherwise serialized representation
    def dump
      return self.connection.dump(@key)
    end

    # Restores the struct to its serialized value as given
    # @param [String] serialized serialized representation of the value
    # @param [#to_f] ttl the time to live for the struct; defaults to 0 (meaning no expiry). 0.001 == 1ms
    # @raise [Redis::CommandError] raised if the serialized value is incompatible or the key already exists
    # @return [Boolean] true if restored, false otherwise
    def restore(serialized, ttl: 0)
      ttl = (ttl.to_f * 1000).floor
      return self.connection.restore(@key, ttl, serialized)
    end

    # # @!visibility private
    def inspectable_attributes
      super.merge(key: @key)
    end
  end
end
