# frozen_string_literal: true
require 'redstruct/types/base'
require 'redstruct/utils/coercion'

module Redstruct
  module Types
    class Struct < Redstruct::Types::Base
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

      # @return [Fixnum] 0 if nothing was deleted in the DB, 1 if it was
      def delete
        self.connection.del(@key)
      end

      # Sets the key to expire after ttl seconds
      # @param [Integer, #to_i] ttl the time to live in seconds (or milliseconds if ms is true)
      # @param [Boolean] ms if true, assumes ttl is in milliseconds
      # @return [Boolean] true if expired, false otherwise
      def expire(ttl, ms: false)
        expired = if ms
          self.connection.pexpire(@key, ttl.to_i)
        else
          self.connection.expire(@key, ttl.to_i)
        end

        return coerce_bool(expired)
      end

      # Sets the key to expire at the given timestamp.
      # @param [Time, Integer, #to_i] time time or unix timestamp at which the key should expire
      # @param [Boolean] ms if true, assumes the timestamp is in milliseconds
      # @return [Boolean] true if expired, false otherwise
      def expire_at(time, ms: false)
        expired = if ms
          time = (time.to_f * 1000) if time.is_a?(Time)
          self.connection.pexpireat(@key, time.to_i)
        else
          self.connection.expireat(@key, time.to_i)
        end

        return coerce_bool(expired)
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

      # :nocov:
      def inspectable_attributes
        super.merge(key: @key)
      end
      # :nocov:
    end
  end
end
