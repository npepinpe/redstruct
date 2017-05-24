# frozen_string_literal: true

require 'redstruct/struct'
require 'redstruct/utils/scriptable'
require 'redstruct/utils/iterable'

module Redstruct
  # Class to manipulate redis lists, modeled after Ruby's Array class.
  # TODO: Add maximum instance variable and modify all methods (where applicable)
  # to take it into account.
  class List < Redstruct::Struct
    include Redstruct::Utils::Scriptable
    include Redstruct::Utils::Iterable

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
    # @raise Redis::BaseError when index is out of range
    # @return [Boolean] true if set, false otherwise
    def []=(index, value)
      return coerce_bool(set_script(keys: @key, argv: [index.to_i, value]))
    end

    # Inserts the given value at the given zero-based index.
    # TODO: Support multiple insertion like Array#insert? The biggest issue
    # here is that concatenating lists in Lua is O(n), so on very large lists,
    # this operation would become slow. There are Redis Modules which implement
    # splice operations (so a O(1) list split/merge), but there's no way to
    # guarantee if the module will be present. Perhaps provide optional support
    # if the module is detected?
    # @param [#to_s] value the value to insert
    # @param [#to_i] index the index at which to insert the value
    def insert(value, index)
      result = case index
      when 0 then prepend(value)
      when -1 then append(value)
      else
        index += 1 if index.negative?
        insert_script(keys: @key, argv: [value, index])
      end

      return coerce_bool(result)
    end

    # Appends the given items (from the right) to the list
    # @param [Array<#to_s>] items the items to append
    # @param [Integer] max optional; if given, appends the items and trims down the list to max afterwards
    # @param [Boolean] exists optional; if true, only appends iff the list already exists (i.e. is not empty)
    # @return [Integer] the number of items appended to the list
    def append(*items, max: 0, exists: false)
      max = max.to_i
      results = if max.positive? || exists
        push_and_trim_script(keys: @key, argv: [max - 1, false, exists] + items)
      else
        self.connection.rpush(@key, items)
      end

      return results
    end
    alias push append

    # Pushes the given element onto the list. As << is a binary operator, it can
    # only take one argument in. It's more of a convenience method.
    # @param [#to_s] item the item to append to the list
    # @return [Integer] 1 if appended, 0 otherwise
    def <<(item)
      return append(item)
    end

    # Prepends the given items (from the right) to the list
    # @param [Array<#to_s>] items the items to prepend
    # @param [Integer] max optional; if given, prepends the items and trims down the list to max afterwards
    # @param [Boolean] exists optional; if true, only prepends iff the list already exists (i.e. is not empty)
    # @return [Integer] the number of items prepended to the list
    def prepend(*items, max: nil, exists: false)
      max = max.to_i

      # redis literally prepends each element one at a time, so 1 2 will end up 2 1
      # to keep behaviour in sync with Array#unshift we preemptively reverse the list
      items = items.reverse

      results = if max.positive? || exists
        push_and_trim_script(keys: @key, argv: [max - 1, true, exists] + items)
      else
        self.connection.lpush(@key, items)
      end

      return results
    end
    alias unshift prepend

    # Pops an item from the list, optionally blocking to wait until the list is non-empty
    # @param [Integer] timeout the amount of time to wait in seconds; if 0, waits indefinitely
    # @return [nil, String] nil if the list was empty, otherwise the item
    def pop(size = 1, timeout: nil)
      raise ArgumentError, 'size must be positive' unless size.positive?

      if timeout.nil?
        return self.connection.rpop(@key) if size == 1
        return shift_pop_script(keys: @key, argv: [-size, -1, 1])
      else
        raise ArgumentError, 'timeout is only supported if size == 1' unless size == 1
        return self.connection.brpop(@key, timeout: timeout)&.last
      end
    end

    # Shifts an item from the list, optionally blocking to wait until the list is non-empty
    # @param [Integer] timeout the amount of time to wait in seconds; if 0, waits indefinitely
    # @return [nil, String] nil if the list was empty, otherwise the item
    def shift(size = 1, timeout: nil)
      raise ArgumentError, 'size must be positive' unless size.positive?

      if timeout.nil?
        return self.connection.lpop(@key) if size == 1
        return shift_pop_script(keys: @key, argv: [0, size - 1, 0])
      else
        raise ArgumentError, 'timeout is only supported if size == 1' unless size == 1
        return self.connection.blpop(@key, timeout: timeout)&.last
      end
    end

    # Pops an element from this list and shifts it onto the given list.
    # @param [Redstruct::List] list the list to shift the element onto
    # @param [#to_i] timeout optional timeout to wait for in seconds
    # @return [String] the element that was popped from the list and pushed onto the other
    def popshift(list, timeout: nil)
      raise ArgumentError, 'list must respond to #key' unless list.respond_to?(:key)

      if timeout.nil?
        return self.connection.rpoplpush(@key, list.key)
      else
        return self.connection.brpoplpush(@key, list.key, timeout: timeout)
      end
    end

    # Removes the given item from the list.
    # @param [Integer] count count > 0: Remove items equal to value moving from head to tail.
    #                        count < 0: Remove items equal to value moving from tail to head.
    #                        count = 0: Remove all items equal to value.
    # @return [Integer] the number of items removed
    def remove(value, count: 1)
      self.connection.lrem(@key, count.to_i, value)
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
      length = length.to_i
      end_index = length.positive? ? start + length - 1 : length

      return self.connection.lrange(@key, start.to_i, end_index)
    end

    # Loads all items into memory and returns an array.
    # NOTE: if the list is expected to be large, use to_enum
    # @return [Array<String>] the items in the list
    def to_a
      return slice(start: 0, length: -1)
    end

    # Since the list can be modified in between loops, this does not guarantee
    # completion of the operation, nor that every single element of the list
    # will be visited once; rather, it guarantees that it loops until no more
    # elements are returned, using an incrementing offset.
    # This means that should elements be removed in the meantime, they will
    # not be seen, and others might be skipped as a result of this.
    # If elements are added, it is however not an issue (although keep in mind
    # that if elements are added faster than consumed, this can loop forever)
    # @return [Enumerator] base enumerator to iterate of the list elements
    def to_enum(match: '*', count: 10)
      pattern = Regexp.compile("^#{Regexp.escape(match).gsub('\*', '.*')}$")

      return Enumerator.new do |yielder|
        offset = 0
        loop do
          items = slice(start: offset, length: offset + count)

          offset += items.size
          matched = items.select { |item| item =~ pattern }
          yielder << matched unless matched.empty?

          raise StopIteration if items.size < count
        end
      end
    end

    # @!group Lua Scripts

    # Appends or prepends (argv[1]) a number of items (argv[2]) to a list (keys[1]),
    # then trims it out to size (argv[3])
    # @param [Array<#to_s>] keys first key should be the key to the list to prepend to and resize
    # @param [Array<Integer, Integer, Integer, Array<#to_s>>] argv the maximum size of the list; if 1, will lpush, otherwise rpush;
    #                                                              if 1, will push only if the list exists; the list of items to prepend
    # @return [Integer] the length of the list after the operation
    defscript :push_and_trim_script, <<~LUA
      local max = tonumber(table.remove(ARGV, 1))
      local prepend = tonumber(table.remove(ARGV, 1)) == 1
      local exists = tonumber(table.remove(ARGV, 1)) == 1
      local push = prepend and 'lpush' or 'rpush'
      local size = 0

      if exists then
        if redis.call('exists', KEYS[1]) == 0 then
          return nil
        end
      end

      size = redis.call(push, KEYS[1], unpack(ARGV))
      if max > 0 and size > max then
        redis.call('ltrim', KEYS[1], 0, max)
        size = max + 1
      end

      return size
    LUA
    protected :push_and_trim_script

    # Removes N elements from the list (either from the head or the tail) and trims
    # the list down to size (either from the head or the tail).
    # @param [Array<#to_s>] keys first key should be the key to the list to prepend to and resize
    # @param [Array<Integer, Integer>] argv the start of the slice; the end index of the slice
    # @return [Integer] the sliced list
    defscript :shift_pop_script, <<~LUA
      local range_start = tonumber(ARGV[1])
      local range_end = tonumber(ARGV[2])
      local direction = tonumber(ARGV[3])
      local list = redis.call('lrange', KEYS[1], range_start, range_end)

      if #list > 0 then
        if direction == 0 then
          redis.call('ltrim', KEYS[1], range_end + 1, -1)
        else
          redis.call('ltrim', KEYS[1], 0, range_start - 1)
        end
      end

      return list
    LUA
    protected :shift_pop_script

    # Inserts the given element at the given index. Can raise out of bound error
    # @param [Array<#to_s>] keys first key is the list key
    # @param [Array<#to_s, #to_i>] argv the value to insert; the index at which to insert it
    # @return [Boolean] true if inserted, false otherwise
    defscript :insert_script, <<~LUA
      local value = ARGV[1]
      local index = tonumber(ARGV[2])
      local pivot = redis.call('lindex', KEYS[1], index - 1)

      if pivot ~= nil then
        return redis.call('linsert', KEYS[1], 'AFTER', pivot, value)
      end

      return false
    LUA
    protected :insert_script

    # Sets the element in much the same way a ruby array would, by padding
    # with empty strings (redis equivalent of nil) when the index is out of range
    # @param [Array<#to_s>] keys first key is the list key
    # @param [Array<#to_s, #to_i>] argv the index to set; the value to set
    # @return [Boolean] true if inserted, false otherwise
    defscript :set_script, <<~LUA
      local index = tonumber(ARGV[1])
      local value = ARGV[2]
      local max = redis.call('llen', KEYS[1]) - 1

      if max < index then
        local upto = index - max - 1
        local items = {}
        for i = index - max - 1, 1, -1 do
          items[#items+1] = ''
        end

        items[#items+1] = value
        return redis.call('rpush', KEYS[1], unpack(items))
      end

      return redis.call('lset', KEYS[1], index, value)
    LUA
    protected :set_script

    # @!endgroup
  end
end
