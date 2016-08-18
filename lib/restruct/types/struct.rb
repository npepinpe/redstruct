require 'forwardable'

module Restruct
  module Types
    class Struct < Restruct::Types::Base
      include Restruct::Utils::Inspectable

      # @return [TrueClass|FalseClass] Returns true if it exists in redis, false otherwise
      def exists?
        return self.connection.exists(@key)
      end

      # @return [Number] 0 if nothing was deleted in the DB, 1 if it was
      def delete
        self.connection.del(@key)
      end

      # @return
      def expire(ttl)
        self.connection.expire(@key, ttl)
      end

      # @return
      def expire_at(time)
        self.connection.expire_at(@key,  time.to_i)
      end

      # @return
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
