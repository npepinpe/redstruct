# frozen_string_literal: true

module Redstruct
  class SortedSet
    # Utility class to allow operations on portions of the set only
    class Slice
      include Redstruct::Utils::Inspectable

      # @param [String, Float] lower lower bound for the slice operation
      # @param [String, Float] upper upper bound for the slice operation
      # @param [Boolean] lex if true, uses lexicographic operations
      # @param [Boolean] exclusive if true, assumes bounds are exclusive
      def initialize(set, lower: nil, upper: nil, lex: false, exclusive: false)
        @set = set
        @lex = lex
        @exclusive = exclusive

        lower ||= -Float::INFINITY
        upper ||= Float::INFINITY

        if @lex
          @lower = parse_lex_bound(lower)
          @upper = parse_lex_bound(upper)
        else
          @lower = parse_bound(lower)
          @upper = parse_bound(upper)
        end
      end

      # @return [Array<String>] returns an array of values for the given bounds
      def to_a
        if @lex
          @set.connection.zrangebylex(@set.key, @lower, @upper)
        else
          @set.connection.zrangebyscore(@set.key, @lower, @upper)
        end
      end

      # @return [Array<String>] returns an array of values reversed
      def reverse
        if @lex
          @set.connection.zrevrangebylex(@set.key, @lower, @upper)
        else
          @set.connection.zrevrangebyscore(@set.key, @lower, @upper)
        end
      end

      # @return [Integer] the number of elements removed
      def remove
        if @lex
          @set.connection.zremrangebylex(@set.key, @lower, @upper)
        else
          @set.connection.zremrangebyscore(@set.key, @lower, @upper)
        end
      end

      # @return [Integer] number of elements in the slice
      def size
        if @lex
          @set.connection.zlexcount(@set.key, @lower, @upper)
        else
          @set.connection.zcount(@set.key, @lower, @upper)
        end
      end

      def inspectable_attributes
        { lower: @lower, upper: @upper, lex: @lex, exclusive: @exclusive, set: @set.key }
      end

      private

      # ( is exclusive, [ is inclusive
      def parse_lex_bound(bound)
        case bound
        when -Float::INFINITY then '-'
        when Float::INFINITY then '+'
        else @exclusive ? "(#{bound}" : "[#{bound}"
        end
      end

      # ( is exclusive
      def parse_bound(bound)
        case bound
        when -Float::INFINITY then '-inf'
        when Float::INFINITY then '+inf'
        else @exclusive ? "(#{bound.to_f}" : bound.to_f
        end
      end
    end
  end
end
