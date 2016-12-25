# frozen_string_literal: true
require 'redstruct/sorted_set'

module Redstruct
  # Mapping between Redis and Ruby sorted sets (with scores). There is no caching mechanism in play, so most methods actually do access
  # the underlying redis connection. Also, keep in mind Redis converts all values strings on the DB side
  # For a set sorted using arbitrary score (and not the item values), see Redstruct::SortedSet
  # @see Redstruct::SortedSet
  class LexSortedSet < Redstruct::SortedSet
    # Returns the number of items between lower and upper bounds.
    # By default lower and upper are inclusive. If you want to make them exclusive, prepend the value with "("
    # @param [#to_s] lower lower bound for the slice operation, either a string, or -inf if no lower bound; defaults to -inf
    # @param [#to_s] upper upper bound for the slice operation, either a string, or +inf if no lower bound; defaults to +inf
    # @return [Integer] the number of items in the given range
    def count(lower: nil, upper: nil)
      return self.connection.zlexcount(@key, parse_bound(lower, '-inf'), parse_bound(upper, '+inf'))
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
        bound.to_s
      end
    end
    private :parse_bound
  end
end
