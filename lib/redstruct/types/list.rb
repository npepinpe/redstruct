module Redstruct
  module Types
    class List < Redstruct::Types::Struct
      include Redstruct::Utils::Scriptable

      def clear
        delete
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
        return push_and_trim_script(keys: @key, argv: [max - 1, 0] + elements)
      end

      def prepend(*elements, max: nil)
        max = max.to_i
        return self.connection.lpush(@key, elements) if max <= 0
        return push_and_trim_script(keys: @key, argv: [max - 1, 1] + elements)
      end

      def pop(timeout: nil)
        return timeout.nil? ? self.connection.lpop(@key) : self.connection.blpop(@key, timeout: timeout)&.last
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

      # Appends or prepends (argv[1]) a number of items (argv[2]) to a list (keys[1]),
      # then trims it out to size (argv[3])
      # @param [Array<(::String)>] keys First key should be the key to the list to prepend to and resize
      # @param [Array<(Fixnum, Fixnum, Array<::String>)>] argv The maximum size of the list; if 1, will lpush, otherwise rpush; the list of items to prepend
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
