# frozen_string_literal: true
module Redstruct
  module Types
    class SortedSet < Redstruct::Types::Struct
      # @param [Array<Array<#to_f, #to_s>>] pairs a list of pairs, where the first element is the score, and second the value
      # @return [Integer] returns the amount of pairs inserted
      def add(*pairs)
        return self.connection.zadd(@key, pairs)
      end

      # @param [Array<#to_s>] values list of member values to remove from the set
      # @return [Integer] the amount of elements removed
      def remove(*values)
        return self.connection.zrem(@key, values)
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
      # By default lower and upper are inclusive. If you want to make them exclusive, prepend the value with "("
      # @param [#to_s, #to_f] lower lower bound for the count range
      # @param [#to_s, #to_f] upper upper bound for the count range
      # @return [Integer] the number of items in the given range
      def count(lower: nil, upper: nil)
        return slice(lower: lower, upper: upper).size
      end

      # Returns a slice or partial selection of the set.
      # @param [#to_s, #to_f] lower lower bound for the slice operation; it should be a simple float
      # @param [#to_s, #to_f] upper upper bound for the slice operation; it should be a simple float
      # @return [Redstruct::Types::SortedSet::Slice] sorted slice by given bounds, as list of pairs: (score, value)
      def slice(lower: nil, upper: nil)
        return self.class::Slice.new(self, lower: lower, upper: upper)
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
      alias include? contain?

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
      # @return [Array<Redstruct::Utils::ScoredValue>] all the items in the set, sorted by score ascending
      # @see Redis#zrange
      def to_a
        return slice.to_a
      end

      # Utility class to allow operations on portions of the set only
      class Slice
        include Redstruct::Utils::Inspectable

        # @param [String, Float] lower lower bound for the slice operation
        # @param [String, Float] upper upper bound for the slice operation
        def initialize(set, lower: nil, upper: nil)
          @set = set
          @lower = parse_bound(lower || '-inf')
          @upper = parse_bound(upper || '+inf')
        end

        # @return [Array<String>] returns an array of values for the given scores
        def to_a
          @set.connection.zrangebyscore(@set.key, @lower, @upper)
        end

        # @return [Integer] the number of elements removed
        def remove
          @set.connection.zremrangebyscore(@set.key, @lower, @upper)
        end

        # @return [Integer] number of elements in the slice
        def size
          @set.connection.zcount(@set.key, @lower, @upper)
        end

        def inspectable_attributes
          { lower: @lower, upper: @upper, set: @set }
        end

        private

        def parse_bound(bound)
          case bound
          when -Float::INFINITY
            '-inf'
          when Float::INFINITY
            '+inf'
          else
            bound
          end
        end
      end
    end
  end
end
