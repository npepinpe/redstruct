# frozen_string_literal: true
require 'redstruct/types/sorted_set/item'

module Redstruct
  module Types
    class SortedSet < Redstruct::Types::Struct
      # A sorted set with the by_value flag set to true is the redis equivalent of a lexicographically sorted set
      # Since sorted sets values are stored as strings on redis, sorting by value is essentially equivalent to sorting strings.
      # @param [Boolean] by_value if true, sorting is done on the value of the item, as opposed to an expected given (value, score) pair
      # @param [Float] default_score the default score when none is provided
      def initialize(by_value: false, default_score: 1.0)
        @by_value = by_value
        @default_score = default_score
      end

      # Removes all items from the set. Does this by simply deleting the key
      # @see Redstruct::Struct#delete
      def clear
        delete
      end

      # Returns the cardinality of the set
      # @return [Integer] how many items are in the set
      def size
        return self.connection.zcard(@key)
      end

      # Returns the number of items between lower and upper bounds.
      # If the set is by_value, then lower and upper should be strings that are essentially prefixes of potential values.
      # If the set is not by_value, the lower and upper should be floats representing lower and upper scores.
      # By default lower and upper are inclusive. If you want to make them exclusive, prepend the value with "("
      # @param [#to_s, #to_f] lower lower bound for the count range
      # @param [#to_s, #to_f] upper upper bound for the count range
      # @return [Integer] the number of items in the given range
      def count(lower: nil, upper: nil)
        count = if @by_value
          self.connection.zlexcount(@key, parse_lex_bound(lower, '-inf'), parse_lex_bound(upper, '+inf'))
        else
          self.connection.zcount(@key, parse_score_bound(lower, '-'), parse_score_bound(upper, '+'))
        end

        return count
      end

      # Returns a slice or partial selection of the set.
      # @param [#to_s, #to_f] lower lower bound for the slice operation; for by_value sets, see #count for the syntax. otherwise it should be a simple float
      # @param [#to_s, #to_f] upper upper bound for the slice operation; for by_value sets, see #count for the syntax. otherwise it should be a simple float
      # @return [Array<String>, Array<Redstruct::Types::SortedSet::Item>] sorted slice by given bounds
      def slice(lower: nil, upper: nil)
        items = if @by_value
          self.connection.zrangelex(@key, parse_lex_bound(lower, '-inf'), parse_lex_bound(upper, '+inf'))
        else
          self.connection.zrange(@key, lower.to_f, upper.to_f).map { |(value, score)| Redstruct::Types::SortedSet::Item.new(value: value, score: score) }
        end

        return items
      end

      # Checks if the set contains any items.
      # @return [Boolean] true if the key exists (meaning it contains at least 1 item), false otherwise
      def empty?
        return !self.connection.exists?
      end

      # @param [#to_s] item the item to check for
      # @return [Boolean] true if the item is in the set, false otherwise
      def contain?(item)
        return !index(item).nil?
      end
      alias_method :include?, :contain?

      # Returns the index of the item in the set, sorted ascending by score
      # @param [#to_s] item the item to check for
      # @return [Integer, nil] the index of the item, or nil if not found
      # @see Redis#zrank
      def index(item)
        return self.connection.zrank(@key, item)
      end

      # Returns the index of the item in the set, sorted descending by score
      # @param [#to_s] item the item to check for
      # @return [Integer, nil] the index of the item, or nil if not found
      # @see Redis#zrevrank
      def rindex(item)
        return self.connection.zrevrank(@key, item)
      end

      # Returns an array representation of the set, sorted by score ascending
      # NOTE: It pulls the whole set into memory, so use each if that's a concern
      # @return [Array<String>, Array<Redstruct::Types::SortedSet::Item>] all the items in the set, sorted by score ascending
      # @see Redis#zrange
      def to_a
        return slice
      end

      # Returns all items sorted by score, with the score available through the Item struct.
      # NOTE: It pulls the whole set into memory, so use each if that's a concern
      # @return [SortedSet<String>, SortedSet<Redstruct::Types::SortedSet::Item>] a sorted set of all items, sorted by Item#score
      def to_set
        return ::SortedSet.new(slice)
      end

      def parse_score_bound(bound, default) # :nodoc:
        case bound
        when nil
          default
        when -Float::INFINITY
          '-inf'
        when Float::INFINITY
          '+inf'
        else
          bound.to_f
        end
      end

      def parse_lex_bound(bound, default) # :nodoc:
        case bound
        when nil
          default
        when -Float::INFINITY
          '-'
        when Float::INFINITY
          '+'
        else
          bound.to_s
        end
      end
    end
  end
end
