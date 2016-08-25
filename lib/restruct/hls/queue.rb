module Restruct
  module Hls
    class Queue < Restruct::Types::List
      include Restruct::Utils::Scriptable

      def enqueue(*elements)
        self.connection.rpush(@key, elements)
      end

      def dequeue(length: 1)
        elements = dequeue_script(keys: @key, argv: length)
        length == 1 ? elements.first : elements
      end

      # Dequeues up to argv[1] amount of items from the list at keys[1]
      # @param [Array<(::String)>] keys The key of the list to dequeue from
      # @param [Array<(Fixnum)>] argv The number of items to dequeue
      # @return [Array] An array of items dequeued or an empty array
      defscript :dequeue_script, <<~LUA
        local length = tonumber(ARGV[1])
        local elements = redis.call('lrange', KEYS[1], 0, length - 1)
        redis.call('ltrim', KEYS[1], length, -1)

        return elements
      LUA
      protected :dequeue_script
    end
  end
end
