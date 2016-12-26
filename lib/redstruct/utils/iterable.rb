# frozen_string_literal: true
module Redstruct
  module Utils
    # Adds iterable capabilities to any object which implements a to_enum method with the correct arguments.
    module Iterable
      # Iterates over the keys of this factory using one of the redis scan commands (scan, zscan, hscan, sscan)
      # For more about the scan command, see https://redis.io/commands/scan
      # @param [String] match will prepend the factory namespace to the match string; see the redis documentation for the syntax
      # @param [Integer] count maximum number of items returned per iteration
      # @param [Integer] max maximum number of iterations; if none given, could potentially never terminate
      # @return [Enumerator] if no block given, returns an enumerator that you can chain with others
      def each(match: '*', count: nil, max: 10_000, &block)
        enumerator = to_enum(match: match, count: count)
        enumerator = enumerator.each_slice(count) unless count.nil?
        enumerator = Redstruct::Utils::Iterable.bound_enumerator(enumerator, max: max.to_i) unless max.nil?

        return enumerator unless block_given?
        return enumerator.each(&block)
      end

      # Including classes should overload this class to provide an initial enumerator
      # NOTE: to namespace the matcher (which you should), use `@factory.isolate(match)`
      # @param [String] match see the redis documentation for the syntax
      # @param [Integer] count maximum number of items returned per iteration
      def to_enum(match:, count:) # rubocop: disable Lint/UnusedMethodArgument
        raise NotImplementedError.new, 'including classes should overload to_enum'
      end

      class << self
        # Returns an enumerator which limits the maximum number of iterations
        # possible on another enumerator.
        # @param [Enumerator] enumerator the unbounded enumerator to wrap
        # @param [Integer] max maximum number of iterations possible
        # @return [Enumerator]
        def bound_enumerator(enumerator, max:)
          raise ArgumentError, 'max must be greater than 0' unless max.positive?

          return Enumerator.new do |yielder|
            iterations = 0
            loop do
              yielder << enumerator.next
              iterations += 1
              raise StopIteration if iterations == max
            end
          end
        end
      end
    end
  end
end
