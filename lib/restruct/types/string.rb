module Restruct
  module Types
    class String < Restruct::Types::Struct
      include Restruct::Utils::Scriptable

      # SCRIPTS
      SCRIPT_DELETE_IF_EQUALS = %(if redis.call("get", KEYS[1]) == ARGV[1] then return redis.call("del", KEYS[1]) else return 0 end).freeze
      # SCRIPTS

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
        script_eval(SCRIPT_DELETE_IF_EQUALS, value) == 1
      end

      # @param [Object] The object to store; note, it will be stored using a string representation
      # @return [String] The old value before setting it
      def getset(value)
        self.connection.getset(@key, value)
      end
    end
  end
end
