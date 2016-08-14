module Restruct
  module Types
    class Counter < Restruct::Types::String
      def initialize(increment: 1, **options)
        super(**options)
        @increment = increment
      end

      def get
        super.to_i
      end

      def set(value)
        super(value.to_i)
      end

      def increment(by: nil)
        by ||= @increment
        value = self.connection.incrby(@key, by.to_i).to_i
        return value
      end

      def decrement(by: nil)
        by ||= @increment
        value = self.connection.decrby(@key, by.to_i).to_i
        return value
      end

      def getset(value)
        return super(value.to_i).to_i
      end
    end
  end
end
