# frozen_string_literal: true

module Redstruct
  class SortedSet
    # Utility class to allow operations on portions of the set only
    # TODO: Support #length property (using LIMIT offset count) of the different
    # range commands, so a slice could be defined as starting at offset X and
    # having length Y, instead of just starting at X and finishing at Y.
    class Slice < Redstruct::Factory::Object
      # @return [String] the key for the underlying sorted set
      attr_reader :key

      # @return [String, Float] the lower bound of the slice
      attr_reader :lower

      # @return [String, Float] the upper bound of the slice
      attr_reader :upper

      # @return [Boolean] if true, then assumes the slice is lexicographically sorted
      attr_reader :lex

      # @return [Boolean] if true, assumes the range bounds are exclusive
      attr_reader :exclusive

      # @param [String, Float] lower lower bound for the slice operation
      # @param [String, Float] upper upper bound for the slice operation
      # @param [Boolean] lex if true, uses lexicographic operations
      # @param [Boolean] exclusive if true, assumes bounds are exclusive
      def initialize(set, lower: nil, upper: nil, lex: false, exclusive: false)
        super(factory: set.factory)

        @key = set.key
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
          self.connection.zrangebylex(@key, @lower, @upper)
        else
          self.connection.zrangebyscore(@key, @lower, @upper)
        end
      end

      # @return [Array<String>] returns an array of values reversed
      def reverse
        if @lex
          self.connection.zrevrangebylex(@key, @lower, @upper)
        else
          self.connection.zrevrangebyscore(@key, @lower, @upper)
        end
      end

      # @return [Integer] the number of elements removed
      def remove
        if @lex
          self.connection.zremrangebylex(@key, @lower, @upper)
        else
          self.connection.zremrangebyscore(@key, @lower, @upper)
        end
      end

      # @return [Integer] number of elements in the slice
      def size
        if @lex
          self.connection.zlexcount(@key, @lower, @upper)
        else
          self.connection.zcount(@key, @lower, @upper)
        end
      end

      # TODO: consider using SortedSet, some other data structure, or nothing
      # @return [::Set] an unordered set representation of the slice
      def to_set
        ::Set.new(to_a)
      end

      def inspectable_attributes
        { lower: @lower, upper: @upper, lex: @lex, exclusive: @exclusive, key: @key }
      end

      private

      # ( is exclusive, [ is inclusive
      def parse_lex_bound(bound)
        case bound
        when -Float::INFINITY then '-'
        when Float::INFINITY then '+'
        else prefix(bound, inclusion: '[', exclusion: '(')
        end
      end

      # ( is exclusive
      def parse_bound(bound)
        case bound
        when -Float::INFINITY then '-inf'
        when Float::INFINITY then '+inf'
        when String then prefix(bound, exclusion: '(')
        else prefix(bound.to_f, exclusion: '(')
        end
      end

      def prefix(value, inclusion: '', exclusion: '')
        prefix = @exclusive ? exclusion : inclusion
        prefixed = value
        prefixed = "#{prefix}#{value}" unless prefix.empty? || prefixed.to_s.start_with?(prefix)

        return prefixed
      end
    end
  end
end
