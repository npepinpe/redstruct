module Restruct
  module Types
    class Queue < Restruct::Types::List
      include Restruct::Utils::Scriptable

      # SCRIPTS
      DEQUEUE_SCRIPT = <<~LUA
        local length = tonumber(ARGV[1])
        local elements = redis.call('lrange', KEYS[1], 0, length - 1)
        redis.call('ltrim', KEYS[1], length, -1)

        return elements
      LUA
      # SCRIPTS

      def enqueue(*elements)
        self.connection.rpush(@key, elements)
      end

      def dequeue(length: 1)
        elements = script_eval(DEQUEUE_SCRIPT, values: length)
        length == 1 ? elements.first : elements
      end
    end
  end
end
