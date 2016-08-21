module Restruct
  module Types
    class String < Restruct::Types::Struct
      include Restruct::Utils::Scriptable, Restruct::Utils::Coercion

      # @return [String] The string value stored in the database
      def get
        return self.connection.get(@key)
      end

      # @param [Object] The object to store; note, it will be stored using a string representation
      # @param [Integer] The expiry time in seconds; if nil, will never expire
      # @param [TrueClass|FalseClass] nx = Not Exists: if true, will not set the key if it already existed
      # @param [TrueClass|FalseClass] xx = Already Exists: if true, will set the key only if it already existed
      # @return [TrueClass|FalseClass] True if set, false otherwise
      def set(value, expiry: nil, nx: nil, xx: nil)
        options = {}
        options[:ex] = expiry.to_i unless expiry.nil?
        options[:nx] = nx unless nx.nil?
        options[:xx] = xx unless xx.nil?

        self.connection.set(@key, value, options) == 'OK'
      end

      # @param [String] The value to compare with
      # @return [TrueClass|FalseClass] True if deleted, false otherwise
      def delete_if_equals(value)
        coerce_bool(delete_if_equals_script(keys: @key, values: value))
      end

      # @param [Object] The object to store; note, it will be stored using a string representation
      # @return [String] The old value before setting it
      def getset(value)
        self.connection.getset(@key, value)
      end

      def length
        self.connection.strlen(@key)
      end

      def slice(start = 0, length = -1)
        length = start + length if length >= 0
        return self.connection.getrange(@key, start, length)
      end

      # Deletes the key (KEYS[1]) iff the value is equal to ARGV[1].
      # KEYS:
      # @param [String] The key to delete
      # ARGV:
      # @param [String] The value to compare with
      # @return [Fixnum] 1 if deleted, 0 otherwise
      defscript :delete_if_equals_script, <<~LUA
        local deleted = false
        if redis.call("get", KEYS[1]) == ARGV[1] then
          deleted = redis.call("del", KEYS[1])
        end

        return deleted
      LUA
    end
  end
end
