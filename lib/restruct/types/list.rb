module Restruct
  module Types
    class List < Restruct::Types::Struct
      def [](index)
        return self.connection.lindex(@key, index.to_i)
      end

      def []=(index, value)
        return self.connection.lset(@key, index.to_i, value)
      end

      def size
        return self.connection.llen(@key)
      end

      def slice(start = 0, length = -1)
        slice = []

        self.connection.pipelined do
          self.connection.lrange(start.to_i, length.to_i)
        end

        return slice
      end
    end
  end
end
