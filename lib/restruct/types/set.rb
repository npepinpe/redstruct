module Restruct
  module Types
    class Set < Restruct::Types::Struct
      def clear
        delete
      end

      def random(count: 1)
        return self.connection.srandmember(@key, count.to_i)
      end

      def empty?
        return !exists?
      end

      def contain?(member)
        return self.connection.sismember(@key, member)
      end
      alias_method :include?, :contain?

      def to_a
        return self.connection.smembers(@key)
      end

      def add(member)
        return self.connection.sadd(@key, member)
      end
      alias_method :<<, :add

      def size
        return self.connection.scard(@key).to_i
      end

      def -(other)
        return ::Set.new(self.connection.sdiff(@key, other.key))
      end

      def +(other)
        return ::Set.new(self.connection.sunion(@key, other.key))
      end

      def |(other)
        return ::Set.new(self.connection.sinter(@key, other.key))
      end

      def difference(other, dest: nil)
        destination = coerce_destination(dest)
        return self - other if destination.nil?
        return self.connection.sdiffstore(destination.key, @key, other.key)
      end

      def intersection(other, dest: nil)
        destination = coerce_destination(dest)
        return self - other if destination.nil?
        return self.connection.interstore(destination.key, @key, other.key)
      end

      def union(other, dest: nil)
        destination = coerce_destination(dest)
        return self - other if destination.nil?
        return self.connection.sunionstore(destination.key, @key, other.key)
      end

      def pop(count: 1)
        return self.connection.spop(@key, count.to_i)
      end

      def remove(*members)
        return self.connection.srem(@key, *members)
      end

      def each(options = {}, &block)
        return self.connection.sscan_each(@key, options, &block)
      end

      def coerce_destination(dest)
        return case dest
        when String
          create { |f| f.set(dest) }
        when Restruct::Type::Set
          dest
        else
          nil
        end
      end
      private :coerce_destination
    end
  end
end
