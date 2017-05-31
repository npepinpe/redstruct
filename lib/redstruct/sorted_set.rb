# frozen_string_literal: true

require 'set'
require 'redstruct/struct'
require 'redstruct/utils/iterable'

module Redstruct
  # Mapping between Redis and Ruby sorted sets (with scores). There is no caching mechanism in play, so most methods actually do access
  # the underlying redis connection. Also, keep in mind Redis converts all values strings on the DB side
  class SortedSet < Redstruct::Struct
    include Redstruct::Utils::Iterable

    # @param [Boolean] lex if true, assumes the set is lexicographically sorted
    def initialize(lex: false, **options)
      super(**options)
      @lex = lex
    end

    # @return [Boolean] true if this is a lexicographically sorted set
    def lexicographic?
      return @lex
    end

    # @param [Array<#to_s>] values the object to add to the set
    # @param [Boolean] exists if true, only update elements that exist (do not add new ones)
    # @param [Boolean] overwrite if false, do not update existing elements
    # @return [Integer] the number of elements that have changed (includes new ones)
    def add(*values, exists: false, overwrite: true)
      options = { xx: exists, nx: !overwrite, ch: true }

      if @lex
        values = values.map do |pair|
          member = pair.is_a?(Array) ? pair.last : pair
          [0.0, member]
        end
      end

      return self.connection.zadd(@key, values, options)
    end

    # @param [#to_s] member the member of the set whose score to increment
    # @param [#to_f] by the amount to increment the score by
    # @return [Float] the new score of the member
    def increment(member, by: 1.0)
      raise NotImplementedError, 'cannot increment the score of items in a lexicographically ordered set' if @lex
      return self.connection.zincrby(@key, by.to_f, member.to_s).to_f
    end

    # @param [#to_s] member the member of the set whose score to decrement
    # @param [#to_f] by the amount to decrement the score by
    # @return [Float] the new score of the member
    def decrement(member, by: 1.0)
      return increment(member, by: -by.to_f)
    end

    # Removes all items from the set. Does this by simply deleting the key
    # @see Redstruct::Struct#delete
    def clear
      delete
    end

    # Returns the number of items in the set. If you want to specify within a
    # range, first get the slice and query its size.
    # @return [Integer] the number of items in the set
    def size
      return self.connection.zcard(@key)
    end

    # Returns a slice or partial selection of the set.
    # @see Redstruct::SortedSet::Slice#initialize
    # @return [Redstruct::SortedSet::Slice] a newly created slice for this set
    def slice(**options)
      defaults = {
        lower: nil,
        upper: nil,
        exclusive: false,
        lex: @lex
      }

      self.class::Slice.new(self, **defaults.merge(options))
    end

    # Checks if the set contains any items.
    # @return [Boolean] true if the key exists (meaning it contains at least 1 item), false otherwise
    def empty?
      return !exists?
    end

    # Relies on the score method, since it is O(1), whereas the index method is
    # O(logn)
    # @param [#to_s] item the item to check for
    # @return [Boolean] true if the item is in the set, false otherwise
    def contain?(item)
      return coerce_bool(score(item))
    end
    alias include? contain?

    # Returns the index of the item in the set, sorted ascending by score
    # @param [#to_s] item the item to check for
    # @return [Integer, nil] the index of the item, or nil if not found
    def index(item)
      return self.connection.zrank(@key, item)
    end

    # Returns the index of the item in the set, sorted descending by score
    # @param [#to_s] item the item to check for
    # @return [Integer, nil] the index of the item, or nil if not found
    def rindex(item)
      return self.connection.zrevrank(@key, item)
    end

    # Returns the score of the given item.
    # @param [#to_s] item the item to check for
    # @return [Float, nil] the score of the item, or nil if not found
    def score(item)
      return self.connection.zscore(@key, item)
    end

    # Removes the items from the set.
    # @param [Array<#to_s>] items the items to remove from the set
    # @return [Integer] the amount of items removed from the set
    def remove(*items)
      return self.connection.zrem(@key, items)
    end

    # Returns an array representation of the set, sorted by score ascending
    # NOTE: It pulls the whole set into memory, so use each if that's a concern,
    # or use slices with pre-determined ranges.
    # @return [Array<Redstruct::Utils::ScoredValue>] all the items in the set, sorted by score ascending
    def to_a
      return slice.to_a
    end

    # TODO: Consider using ::SortedSet or some other data structure
    # @return [::Set] an unordered set representation
    def to_set
      return slice.to_set
    end

    # Use redis-rb zscan_each method to iterate over particular keys
    # @return [Enumerator] base enumerator to iterate of the namespaced keys
    def to_enum(match: '*', count: 10, with_scores: false)
      enumerator = self.connection.zscan_each(@key, match: match, count: count)
      return enumerator if with_scores
      return Enumerator.new do |yielder|
        loop do
          item, = enumerator.next
          yielder << item
        end
      end
    end
  end
end
