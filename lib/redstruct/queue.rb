# frozen_string_literal: true
require 'redstruct/list'

module Redstruct
  # Simple queue implementation, adding the ability to dequeue multiple items at once (not normally possible with lists)
  class Queue < Redstruct::List
    # Enqueues the given items
    # @see Redstruct::List#append
    alias enqueue append

    # Dequeues up to `count` items from the queue.
    # @param [Integer] count the number of items to dequeue; defaults to 1
    # @return [String, Array<String>] if count is 1, returns the item directly, otherwise all dequeued items
    def dequeue(count: 1)
      items = dequeue_script(keys: @key, argv: count)
      count == 1 ? items.first : items
    end

    # Dequeues up to argv[1] amount of items from the list at keys[1]
    # @param [Array<(::String)>] keys the key of the list to dequeue from
    # @param [Array<(Fixnum)>] argv the number of items to dequeue
    # @return [Array] An array of items dequeued or an empty array
    defscript :dequeue_script, <<~LUA
      local count = tonumber(ARGV[1])
      local items = redis.call('lrange', KEYS[1], 0, length - 1)
      redis.call('ltrim', KEYS[1], count, -1)

      return items
    LUA
    protected :dequeue_script
  end
end
