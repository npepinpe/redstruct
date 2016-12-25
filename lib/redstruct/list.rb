# frozen_string_literal: true
require 'redstruct/struct'
require 'redstruct/utils/scriptable'
require 'redstruct/utils/iterable'

module Redstruct
  # Class to manipulate redis lists, modeled after Ruby's Array class.
  class List < Redstruct::Struct
    include Redstruct::Utils::Scriptable, Redstruct::Utils::Iterable

    # Clears the set by simply removing the key from the DB
    # @see Redstruct::Struct#clear
    def clear
      delete
    end

    # Checks if the set is empty by checking if the key actually exists on the underlying redis db
    # @see Redstruct::Struct#exists?
    # @return [Boolean] true if it is empty, false otherwise
    def empty?
      return !exists?
    end

    # Returns the item located at index
    # @param [Integer] index the item located at index
    # @return [String, nil] nil if no item at index, otherwise the value
    def [](index)
      return self.connection.lindex(@key, index.to_i)
    end

    # Sets or updates the value for item at index
    # @param [Integer] index the index
    # @param [#to_s] value the new value
    # @raise Redis::Error when index is out of range
    # @return [Boolean] true if set, false otherwise
    def []=(index, value)
      return coerce_bool(self.connection.lset(@key, index.to_i, value))
    end

    # Appends the given items (from the right) to the list
    # @param [Array<#to_s>] items the items to append
    # @param [Integer] max optional; if given, appends the items and trims down the list to max afterwards
    # @param [Boolean] exists optional; if true, only appends iff the list already exists (i.e. is not empty)
    # @return [Integer] the number of items appended to the list
    def append(*items, max: 0, exists: false)
      max = max.to_i
      results = if max <= 0
        if exists
          self.connection.rpush(@key, items)
        else
          self.connection.rpushx(@key, items)
        end
      else
        push_and_trim_script(keys: @key, argv: [max - 1, false, exists] + items)
      end

      return results
    end

    # Prepends the given items (from the right) to the list
    # @param [Array<#to_s>] items the items to prepend
    # @param [Integer] max optional; if given, prepends the items and trims down the list to max afterwards
    # @param [Boolean] exists optional; if true, only prepends iff the list already exists (i.e. is not empty)
    # @return [Integer] the number of items prepended to the list
    def prepend(*items, max: nil, exists: false)
      max = max.to_i
      results = if max <= 0
        if exists
          self.connection.lpush(@key, items)
        else
          self.connection.lpushx(@key, items)
        end
      else
        push_and_trim_script(keys: @key, argv: [max - 1, true, exists] + items)
      end

      return results
    end

    # Pops an item from the list, optionally blocking to wait until the list is non-empty
    # @param [Integer] timeout the amount of time to wait in seconds; if 0, waits indefinitely
    # @return [nil, String] nil if the list was empty, otherwise the item
    def pop(timeout: nil)
      options = {}
      options[:timeout] = timeout.to_i unless timeout.nil?
      return self.connection.blpop(@key, options)&.last
    end

    # Removes the given item from the list.
    # @param [Integer] count count > 0: Remove items equal to value moving from head to tail.
    #                        count < 0: Remove items equal to value moving from tail to head.
    #                        count = 0: Remove all items equal to value.
    # @return [Integer] the number of items removed
    def remove(value, count: 1)
      count = [1, count.to_i].max
      self.connection.lrem(@key, count, value)
    end

    # Checks how many items are in the list.
    # @return [Integer] the number of items in the list
    def size
      return self.connection.llen(@key)
    end

    # Returns a slice of the list starting at start (inclusively), up to length (inclusively)
    # @example
    #   pry> list.slice(start: 1, length: 10) #=> Array<...> # array with 11 items
    # @param [Integer] start the starting index for the slice; if start is larger than the end of the list, an empty list is returned
    # @param [Integer] length the length of the slice (inclusively); if -1, returns everything
    # @return [Array<String>] the requested slice, or an empty list
    def slice(start: 0, length: -1)
      return self.connection.lrange(@key, start.to_i, length.to_i)
    end

    # Loads all items into memory and returns an array.
    # NOTE: if the list is expected to be large, use to_enum
    # @return [Array<String>] the items in the list
    def to_a
      return slice(0, -1)
    end

    # Appends or prepends (argv[1]) a number of items (argv[2]) to a list (keys[1]),
    # then trims it out to size (argv[3])
    # @param [Array<(::String)>] keys First key should be the key to the list to prepend to and resize
    # @param [Array<(Integer, Integer, Integer, Array<::String>)>] argv The maximum size of the list; if 1, will lpush, otherwise rpush;
    #                                                                   if 1, will push only if the list exists; the list of items to prepend
    # @return [Integer] The length of the list after the operation
    defscript :push_and_trim_script, <<~LUA
      local max = tonumber(table.remove(ARGV, 1))
      local prepend = tonumber(table.remove(ARGV, 1)) == 1
      local exists = tonumber(table.remove(ARGV, 1)) == 1
      local push = prepend and 'lpush' or 'rpush'

      if exists
        push = push .. 'x'
      end

      local size = redis.call(push, KEYS[1], unpack(ARGV))
      if size > max then
        redis.call('ltrim', KEYS[1], 0, max)
        size = max + 1
      end

      return size
    LUA
    protected :push_and_trim_script
  end
end
