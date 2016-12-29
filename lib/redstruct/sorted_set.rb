# frozen_string_literal: true
require 'set'
require 'redstruct/struct'
require 'redstruct/utils/iterable'
require 'redstruct/utils/scored_value'

module Redstruct
  # Mapping between Redis and Ruby sorted sets (with scores). There is no caching mechanism in play, so most methods actually do access
  # the underlying redis connection. Also, keep in mind Redis converts all values strings on the DB side
  # For a lexicographically sorted set (i.e. using the string value instead of a score), see Redstruct::LexSortedSet
  # @see Redstruct::LexSortedSet
  class SortedSet < Redstruct::Struct
    include Redstruct::Utils::Iterable

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
      return self.connection.zcount(@key, parse_bound(lower, '-inf'), parse_bound(upper, '+inf'))
    end

    # Returns a slice or partial selection of the set.
    # @param [#to_s, #to_f] lower lower bound for the slice operation; it should be a simple float
    # @param [#to_s, #to_f] upper upper bound for the slice operation; it should be a simple float
    # @return [Array<Redstruct::Utils::ScoredValue>] sorted slice by given bounds
    def slice(lower: nil, upper: nil)
      return self.connection.zrange(@key, lower.to_f, upper.to_f).map do |(value, score)|
        Redstruct::Utils::ScoredValue.new(value: value, score: score)
      end
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
      return slice
    end

    # Returns all items sorted by score, with the score available through the Item struct.
    # NOTE: It pulls the whole set into memory, so use each if that's a concern
    # @return [Redstruct::Types::SortedSet<Redstruct::Utils::ScoredValue>] a sorted set of all items, sorted by Item#score
    def to_set
      return ::SortedSet.new(slice)
    end

    # Use redis-rb zscan_each method to iterate over particular keys
    # @return [Enumerator] base enumerator to iterate of the namespaced keys
    def to_enum(match: '*', count: 10)
      return self.connection.zscan_each(match: match, count: count)
    end

    def parse_bound(bound, default)
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
    private :parse_bound
  end
end
