# frozen_string_literal: true
require 'redstruct/string'

module Redstruct
  # Additional counter operations, using redis string values.
  class Counter < Redstruct::String
    # @return [Integer] the default increment value of the counter, defaults to 1
    attr_reader :increment

    # @return [Integer] the default maximum value of the counter, leave nil unless you want the cycle effect
    attr_reader :max

    # @param [Integer] increment the default increment value
    # @param [Integer, nil] max the default max value of the counter, leave nil unless you want cyclical counters
    def initialize(increment: 1, max: nil, **options)
      super(**options)
      @increment = increment
      @max = max
    end

    # @return [Integer, nil] the stored value as an integer, or nil if nothing stored
    def get
      result = super
      return result.nil? ? nil : result.to_i
    end

    # Sets the new value, converting it to int first
    # @see Redstruct::String#set
    # @param [#to_i] value the updated counter value
    # @return [Boolean] True if set, false otherwise
    def set(value, **options)
      super(value.to_i, **options)
    end

    # @param [#to_i] value the object to store
    # @return [Integer] the old value before setting it
    def getset(value)
      return super(value.to_i).to_i
    end

    # Increments the counter by the given value. If max is given, will loop around and start again from 0 (will increment by (current_value + by) % max).
    # @param [Integer, nil] by defaults to @increment, used to increment the underlying counter
    # @param [Integer, nil] max if non-nil, the counter will loop and start over from 0 when it reaches max
    # @example
    #   pry> counter.increment(by: 10, max: 5) # returns 0, since 10 % 5 == 0
    #   pry> counter.increment(by: 9, max: 5) # returns 4
    # @return [Integer] the updated value
    def increment(by: nil, max: nil)
      by ||= @increment
      max ||= @max

      value = if max.nil?
        self.connection.incrby(@key, by.to_i).to_i
      else
        ring_increment_script(keys: @key, argv: [by.to_i, max.to_i]).to_i
      end

      return value
    end

    # Decrements the counter by the given value. If max is given, will loop around and start again from 0 (will decrement by (current_value + by) % max).
    # @param [Integer, nil] by defaults to @increment, used to increment the underlying counter
    # @param [Integer, nil] max if non-nil, the counter will loop and start over from 0 when it reaches max
    # @example
    #   pry> counter.decrement(by: 10, max: 5) # returns 0, since 10 % 5 == 0
    #   pry> counter.decrement(by: 9, max: 5) # returns -4
    # @return [Integer] the updated value
    def decrement(by: nil, max: nil)
      by ||= @increment
      by = -by.to_i
      return increment(by: by, max: max)
    end

    defscript :ring_increment_script, <<~LUA
      local by = tonumber(ARGV[1])
      local max = tonumber(ARGV[2])
      local current = redis.call('get', KEYS[1])
      local value = current and tonumber(current) or 0

      value = (value + by) % max
      redis.call('set', KEYS[1], value)

      return value
    LUA
    protected :ring_increment_script

    # @!visibility private
    def inspectable_attributes
      super.merge(max: @max, increment: @increment)
    end
  end
end
