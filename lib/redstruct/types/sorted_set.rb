module Redstruct
  module Types
    class SortedSet < Redstruct::Types::Struct
      DEFAULT_SCORE = 1.0

      def add(options = {}, *items)
        defaults = { nx: false, xx: false, ch: false }
      end

      def <<(item)
        return self.connection.zadd(@key, DEFAULT_SCORE, item)
      end
    end
  end
end
