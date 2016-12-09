require 'forwardable'

module Redstruct
  module Types
    class Struct < Redstruct::Types::Base
      include Redstruct::Utils::Inspectable

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
      def expire(ttl, ms: false)
        if ms
          self.connection.pexpire(@key, ttl.to_i)
        else
          self.connection.expire(@key, ttl.to_i)
        end
      end

      # Sets the key to expire at the given timestamp.
      # @param [Time, Integer, #to_i] time time or unix timestamp at which the key should expire
      # @param [Boolean] ms if true, assumes the timestamp is in milliseconds
      def expire_at(time, ms: false)
        if ms
          time = (time.to_f * 1000) if time.is_a?(Time)
          self.connection.pexpire_at(@key, time.to_i)
        else
          self.connection.expire_at(@key, time.to_i)
        end
      end

      # Removes the expiry time from a key
      def persist
        self.connection.persist(@key)
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
