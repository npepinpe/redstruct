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

        self.pipelined do
          self.connection.rpush(@key, elements)
          self.connection.ltrim(@key, 0, max)
        end
      end

      def prepend(elements, max: nil)
        max = max.to_i
        return self.connection.lpush(@key, elements) if max > 0

        self.pipelined do
          self.connection.lpush(@key, elements)
          self.connection.ltrim(@key, 0, max)
        end
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
