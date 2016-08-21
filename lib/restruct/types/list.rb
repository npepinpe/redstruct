module Restruct
  module Types
    class List < Restruct::Types::Struct
      include Restruct::Utils::Scriptable

      def clear
        return self.connection.ltrim(@key, 1, 0)
      end

      def empty?
        return !exists?
      end

      def [](index)
        return self.connection.lindex(@key, index.to_i)
      end

      def []=(index, value)
        return self.connection.lset(@key, index.to_i, value)
      end

      def append(*elements, max: 0)
        max = max.to_i
        return self.connection.rpush(@key, elements) if max <= 0
        return push_and_trim_script(keys: @key, values: [max - 1, 0] + elements)
      end

      def prepend(*elements, max: nil)
        max = max.to_i
        return self.connection.lpush(@key, elements) if max <= 0
        return push_and_trim_script(keys: @key, values: [max - 1, 1] + elements)
      end

      def pop(timeout: nil)
        options = {}
        options[:timeout] = timeout.to_i unless timeout.nil?
        return self.connection.blpop(@key, options)&.last
      end

      def remove(value, count: 1)
        count = [1, count.to_i].max
        self.connection.lrem(@key, count, value)
      end

      def size
        return self.connection.llen(@key)
      end

      def slice(start = 0, length = -1)
        return self.connection.lrange(@key, start.to_i, length.to_i)
      end

      def to_a
        return slice(0, -1)
      end

      # Appends or prepends (ARGV[1]) a number of items (ARGV[2]) to a list (KEYS[1]),
      # then trims it out to size (ARGV[3])
      # KEYS:
      # @param [String] The list to prepend to and resize
      # ARGV:
      # @param [Fixnum] If 1, will lpush; if false, rpush
      # @param [Fixnum] The maximum size of the list
      # @param [Array<String>] The items to prepend
      # @return [Fixnum] The length of the list after the operation
      defscript :push_and_trim_script, <<~LUA
        local max = tonumber(table.remove(ARGV, 1))
        local prepend = tonumber(table.remove(ARGV, 1)) == 1
        local push = prepend and 'lpush' or 'rpush'

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
end
