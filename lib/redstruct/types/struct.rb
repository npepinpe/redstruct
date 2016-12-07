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

      def expire(ttl)
        self.connection.expire(@key, ttl.to_i)
      end

      def expire_at(time)
        self.connection.expire_at(@key, time.to_i)
      end

      def ttl
        return self.connection.ttl(@key)
      end

      def persist
        self.connection.persist(@key)
      end

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
