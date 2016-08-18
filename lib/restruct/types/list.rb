module Restruct
  module Types
    class List < Restruct::Types::Struct
      include Restruct::Utils::Scriptable

      # SCRIPTS

      # SCRIPTS

      def [](index)
        return self.connection.lindex(@key, index.to_i)
      end

      def []=(index, value)
        return self.connection.lset(@key, index.to_i, value)
      end

      def append(*elements, max: 0)
        max = max.to_i
        return self.connection.rpush(@key, elements) if max > 0

        self.multi do |c|
          c.rpush(@key, elements)
          c.ltrim(@key, 0, max)
        end
      end

      def prepend(elements, max: nil)
        max = max.to_i
        return self.connection.lpush(@key, elements) if max > 0

        self.multi do |c|
          c.lpush(@key, elements)
          c.ltrim(@key, 0, max)
        end
      end

      def pop(timeout: nil)
        options = {}
        options[:timeout] = timeout.to_i unless timeout.nil?
        return self.connection.blpop(@key, options).last
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
    end
  end
end
