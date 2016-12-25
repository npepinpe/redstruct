# frozen_string_literal: true
require 'set'
require 'redstruct/struct'
require 'redstruct/utils/iterable'

module Redstruct
  # Mapping between Redis and Ruby sets. There is no caching mechanism in play, so most methods actually do access
  # the underlying redis connection. Also, keep in mind Redis converts all values strings on the DB side
  class Set < Redstruct::Struct
    include Redstruct::Utils::Iterable

    # Clears the set by simply removing the key from the DB
    # @see Redstruct::Struct#clear
    def clear
      delete
    end

    # Returns random items from the set
    # @param [Integer] count the number of items to return
    # @return [String, Set] if count is one, then return the item; otherwise returns a set
    def random(count: 1)
      list = self.connection.srandmember(@key, count)
      return count == 1 ? list[0] : Set.new(list)
    end

    # Checks if the set is empty by checking if the key actually exists on the underlying redis db
    # @see Redstruct::Struct#exists?
    # @return [Boolean] true if it is empty, false otherwise
    def empty?
      return !exists?
    end

    # Checks if the set contains this particular item
    # @param [#to_s] item the item to check for
    # @return [Boolean] true if the set contains the item, false otherwise
    def contain?(item)
      return coerce_bool(self.connection.sismember(@key, item))
    end
    alias include? contain?

    # Adds the given items to the set
    # @param [Array<#to_s>] items the items to add to the set
    # @return [Boolean, Integer] when only one item, returns true or false on insertion, otherwise the number of items added
    def add(*items)
      return self.connection.sadd(@key, items)
    end
    alias << add

    # Pops and returns an item from the set.
    # NOTE: Since this is a redis set, keep in mind that popping the last element of the set effectively deletes the set
    # @return [String] popped item
    def pop
      return self.connection.spop(@key)
    end

    # Removes the given items from the set.
    # @param [Array<#to_s>] items the items to remove from the set
    # @return [Boolean, Integer] when only one item, returns true or false on deletion, otherwise the number of items removed
    def remove(*items)
      return self.connection.srem(@key, items)
    end

    # @return [Integer] the number of items in the set
    def size
      return self.connection.scard(@key).to_i
    end

    # Computes the difference of the two sets and stores the result in `dest`. If no destination provided, computes
    # the results in memory.
    # @param [Redstruct::Set] other set the set to subtract
    # @param [Redstruct::Set, String] dest if nil, results are computed in memory. if a string, a new Redstruct::Set is
    # constructed with the string as the key, and results are stored there. if already a Redstruct::Set, results are stored there.
    # @return [::Set, Redstruct::Set] if dest was provided, return dest as a Redstruct::Set, otherwise a standard Ruby set containing the difference
    def difference(other, dest: nil)
      destination = coerce_destination(dest)
      results = if destination.nil?
        ::Set.new(self.connection.sdiff(@key, other.key))
      else
        self.connection.sdiffstore(destination.key, @key, other.key)
      end

      return results
    end
    alias - difference

    # Computes the interesection of the two sets and stores the result in `dest`. If no destination provided, computes
    # the results in memory.
    # @param [Redstruct::Set] other set the set to intersect
    # @param [Redstruct::Set, String] dest if nil, results are computed in memory. if a string, a new Redstruct::Set is
    # constructed with the string as the key, and results are stored there. if already a Redstruct::Set, results are stored there.
    # @return [::Set, Redstruct::Set] if dest was provided, return dest as a Redstruct::Set, otherwise a standard Ruby set containing the intersection
    def intersection(other, dest: nil)
      destination = coerce_destination(dest)
      results = if destination.nil?
        ::Set.new(self.connection.sinter(@key, other.key))
      else
        self.connection.sinterstore(destination.key, @key, other.key)
      end

      return results
    end
    alias | intersection

    # Computes the union of the two sets and stores the result in `dest`. If no destination provided, computes
    # the results in memory.
    # @param [Redstruct::Set] other set the set to add
    # @param [Redstruct::Set, String] dest if nil, results are computed in memory. if a string, a new Redstruct::Set is
    #  constructed with the string as the key, and results are stored there. if already a Redstruct::Set, results are stored there.
    # @return [::Set, Redstruct::Set] if dest was provided, return dest as a Redstruct::Set, otherwise a standard Ruby set containing the union
    def union(other, dest: nil)
      destination = coerce_destination(dest)
      results = if destination.nil?
        ::Set.new(self.connection.sunion(@key, other.key))
      else
        self.connection.sunionstore(destination.key, @key, other.key)
      end

      return results
    end
    alias + union

    # Use redis-rb sscan_each method to iterate over particular keys
    # @return [Enumerator] base enumerator to iterate of the namespaced keys
    def to_enum(match:, count:)
      return self.connection.sscan_each(match: match, count: count)
    end

    # Returns an array representation of the set. Ordering is random and defined by redis
    # NOTE: If the set is particularly large, consider using #each
    # @return [Array<String>] an array of all items contained in the set
    def to_a
      return self.connection.smembers(@key)
    end

    # Loads all members of the set and converts them to a Ruby set.
    # NOTE: If the set is particularly large, consider using #each
    # @return [::Set] ruby set of all items stored on redis for this set
    def to_set
      return ::Set.new(to_a)
    end

    def coerce_destination(dest)
      case dest
      when ::String
        @factory.set(dest)
      when self.class
        dest
      end
    end
    private :coerce_destination
  end
end
