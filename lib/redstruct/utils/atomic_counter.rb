# frozen_string_literal: true

module Redstruct
  module Utils
    # Very basic utility class to have thread-safe counters
    class AtomicCounter
      # @param [Integer] initial the initial value of the counter
      def initialize(initial = 0)
        @lock = Mutex.new
        @current = initial
      end

      # Increments the counter by the given delta
      # @param [Integer] by the delta to increment by
      # @return [Integer] the new, incremented value
      def increment(by: 1)
        return @lock.synchronize do
          @current += by.to_i
        end
      end

      # Decrements the counter by the given delta
      # @param [Integer] by the delta to decrement by
      # @return [Integer] the new, decremented value
      def decrement(by: 1)
        return increment(by: -by.to_i)
      end
    end
  end
end
