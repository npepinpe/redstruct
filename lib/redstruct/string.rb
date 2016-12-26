# frozen_string_literal: true
require 'redstruct/struct'
require 'redstruct/utils/scriptable'

module Redstruct
  # Manipulation of redis strings
  class String < Redstruct::Struct
    include Redstruct::Utils::Scriptable

    # @return [String, nil] the string value stored in the database
    def get
      return self.connection.get(@key)
    end

    # @param [#to_s] value the object to store
    # @param [Integer] expiry the expiry time in seconds; if nil, will never expire
    # @param [Boolean] nx Not Exists: if true, will not set the key if it already existed
    # @param [Boolean] xx Already Exists: if true, will set the key only if it already existed
    # @return [Boolean] true if set, false otherwise
    def set(value, expiry: nil, nx: false, xx: false)
      options = { nx: nx, xx: xx }
      options[:ex] = expiry.to_i unless expiry.nil?

      coerce_bool(self.connection.set(@key, value, options))
    end

    # @param [String] value The value to compare with
    # @return [Boolean] True if deleted, false otherwise
    def delete_if_equals(value)
      coerce_bool(delete_if_equals_script(keys: @key, argv: value))
    end

    # @param [#to_s] value The object to store
    # @return [String] The old value before setting it
    def getset(value)
      self.connection.getset(@key, value)
    end

    # @return [Integer] The length of the string
    def length
      self.connection.strlen(@key)
    end

    # @param [Integer] start Starting index of the slice
    # @param [Integer] length Length of the slice; negative numbers start counting from the right (-1 = end)
    # @return [Array<String>] The requested slice from <start> with length <length>
    def slice(start = 0, length = -1)
      length = start + length if length >= 0
      return self.connection.getrange(@key, start, length)
    end

    # Deletes the key (keys[1]) iff the value is equal to argv[1].
    # @param [Array<(::String)>] keys The key to delete
    # @param [Array<(::String)>] argv The value to compare with
    # @return [Integer] 1 if deleted, 0 otherwise
    defscript :delete_if_equals_script, <<~LUA
      local deleted = false
      if redis.call("get", KEYS[1]) == ARGV[1] then
        deleted = redis.call("del", KEYS[1])
      end

      return deleted
    LUA
  end
end
