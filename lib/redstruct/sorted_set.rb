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

    # @param [#to_s] member the object to add to the set
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
      raise 'cannot increment the score of items in a lexicographically ordered set' if @lex
      return self.connection.zincrby(@key, by.to_f, member.to_s).to_f
    end

    # @param [#to_s] member the member of the set whose score to decrement
    # @param [#to_f] by the amount to decrement the score by
    # @return [Float] the new score of the member
    def decrement(member, by: 1.0)
      return increment(member, -by.to_f)
    end

    # Removes all items from the set. Does this by simply deleting the key
    # @see Redstruct::Struct#delete
    def clear
      delete
    end

    # Returns the number of items between lower and upper bounds.
    # By default lower and upper are inclusive. If you want to make them exclusive, prepend the value with "("
    # @param [#to_s, #to_f] lower lower bound for the count range
    # @param [#to_s, #to_f] upper upper bound for the count range
    # @return [Integer] the number of items in the given range
    def size(lower: nil, upper: nil, **options)
      if lower.nil? && upper.nil?
        return self.connection.zcard(@key)
      else
        return slice(options.merge(lower: lower, upper: upper)).size
      end
    end

    # Returns a slice or partial selection of the set.
    # @param [#to_s, #to_f] lower lower bound for the slice operation; it should be a simple float
    # @param [#to_s, #to_f] upper upper bound for the slice operation; it should be a simple float
    # @return [Array<Redstruct::Utils::ScoredValue>] sorted slice by given bounds
    def slice(lower: nil, upper: nil, exclusive: false)
      self.class::Slice.new(self, lower: lower, upper: upper, exclusive: exclusive, lex: @lex)
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

    # Use redis-rb zscan_each method to iterate over particular keys
    # @return [Enumerator] base enumerator to iterate of the namespaced keys
    def to_enum(match: '*', count: 10)
      return self.connection.zscan_each(match: match, count: count)
    end
  end
end
