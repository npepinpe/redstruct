# frozen_string_literal: true

require 'test_helper'

module Redstruct
  class SetTest < Redstruct::Test
    def setup
      super
      @factory = create_factory
      @set = @factory.set('set')
    end

    def test_clear
      @set << 'item'
      refute @set.empty?, 'ensure it is not empty before clearing'

      @set.clear
      assert @set.empty?, 'should be empty after clearing'
    end

    # assumes srandmember works correctly about the randomization part
    def test_random
      ensure_command_called(@set, :srandmember, 1).twice
      assert_nil @set.random, 'should return nothing when the set is empty'

      @set << 'a'
      assert_equal 'a', @set.random, 'should return a, as it is the only member anyway'

      amount = rand(10) + 2
      requested = amount / 2
      @set.add(*(1..amount).map { |i| i })

      ensure_command_called(@set, :srandmember, requested).once
      assert_equal requested, @set.random(count: requested).size, 'should return the amount of items requested'
    end

    def test_empty?
      assert @set.empty?, 'should be initially empty'
      @set << 'a'
      refute @set.empty?, 'should not be empty once it has one element'
      @set.clear
      assert @set.empty?, 'should be empty after clearing'
    end

    def test_contain?
      refute @set.contain?('a'), 'should not contain anything'
      @set << 'a'
      assert @set.contain?('a'), 'should now contain a'
    end

    def test_add
      assert @set.empty?, 'set should be empty before any addition'
      assert_equal 2, @set.add(1, 2), 'should return the number of added elements'
      assert_equal 1, @set.add(1, 2, 3), 'should return only the number of added elements'
      assert_equal ::Set.new(%w[1 2 3]), @set.to_set, 'should return a set containing 1, 2, 3'
    end

    def test_pop
      values = %w[1 2 3]
      assert @set.empty?, 'should start empty'

      @set.add(*values)
      popped = @set.pop
      assert values.include?(popped), 'should have popped one of the added values'

      expected = values - [popped]
      assert_equal ::Set.new(expected), @set.to_set, 'should return a set containing the remaining elements'
    end

    def test_remove
      values = %w[1 2 3]
      assert @set.empty?, 'should start empty'

      @set.add(*values)
      assert @set.remove('1'), 'should remove the element correctly'
      assert_equal ::Set.new(%w[2 3]), @set.to_set, 'should return the remaining elements'

      assert_equal 2, @set.remove(2, 3, 4), 'should remove 2 elements only'
      assert @set.empty?, 'should be empty once we remove everything'
    end

    def test_size
      values = %w[1 2 3]
      assert_equal 0, @set.size, 'should have no elements initially'

      @set.add(*values)
      assert_equal values.size, @set.size, 'should return the correct number of elements'
    end

    def test_difference
      set_contents = %w[1 2 3 4]
      set2_contents = %w[3 4 5 6]

      set2 = @factory.set('set2')

      @set.add(*set_contents)
      set2.add(*set2_contents)

      assert_equal ::Set.new(%w[1 2]), @set - set2, 'should return elements not contained in set2'
      assert_equal ::Set.new(%w[5 6]), set2 - @set, 'should return elements not contained in set'

      assert_equal ::Set.new(set_contents), @set.to_set, 'should still be the same'
      assert_equal ::Set.new(set2_contents), set2.to_set, 'should still be the same'
    end

    def test_difference_dest
      set_contents = %w[1 2 3 4]
      set2_contents = %w[3 4 5 6]

      set2 = @factory.set('set2')
      set3 = @factory.set('set3')

      @set.add(*set_contents)
      set2.add(*set2_contents)

      assert_equal 2, @set.difference(set2, dest: set3), 'should have 2 elements stored in the new set'
      assert_equal ::Set.new(%w[1 2]), set3.to_set, 'should return elements not contained in set2'

      assert_equal ::Set.new(set_contents), @set.to_set, 'should still be the same'
      assert_equal ::Set.new(set2_contents), set2.to_set, 'should still be the same'
    end

    def test_intersection
      set_contents = %w[1 2 3 4]
      set2_contents = %w[3 4 5 6]

      set2 = @factory.set('set2')

      @set.add(*set_contents)
      set2.add(*set2_contents)

      assert_equal ::Set.new(%w[3 4]), @set | set2, 'should return elements contained in both sets'
      assert_equal ::Set.new(%w[3 4]), set2 | @set, 'should return elements contained in both sets'

      assert_equal ::Set.new(set_contents), @set.to_set, 'should still be the same'
      assert_equal ::Set.new(set2_contents), set2.to_set, 'should still be the same'
    end

    def test_intersection_dest
      set_contents = %w[1 2 3 4]
      set2_contents = %w[3 4 5 6]

      set2 = @factory.set('set2')
      set3 = @factory.set('set3')

      @set.add(*set_contents)
      set2.add(*set2_contents)

      assert_equal 2, @set.intersection(set2, dest: set3), 'should have 2 elements stored in the new set'
      assert_equal ::Set.new(%w[3 4]), set3.to_set, 'should return elements contained in both sets'

      assert_equal ::Set.new(set_contents), @set.to_set, 'should still be the same'
      assert_equal ::Set.new(set2_contents), set2.to_set, 'should still be the same'
    end

    def test_union
      set_contents = %w[1 2 3 4]
      set2_contents = %w[3 4 5 6]

      set2 = @factory.set('set2')

      @set.add(*set_contents)
      set2.add(*set2_contents)

      assert_equal ::Set.new(%w[1 2 3 4 5 6]), @set + set2, 'should return elements contained in either sets'
      assert_equal ::Set.new(%w[1 2 3 4 5 6]), set2 + @set, 'should return elements contained in either sets'

      assert_equal ::Set.new(set_contents), @set.to_set, 'should still be the same'
      assert_equal ::Set.new(set2_contents), set2.to_set, 'should still be the same'
    end

    def test_union_dest
      set_contents = %w[1 2 3 4]
      set2_contents = %w[3 4 5 6]

      set2 = @factory.set('set2')
      set3 = @factory.set('set3')

      @set.add(*set_contents)
      set2.add(*set2_contents)

      assert_equal 6, @set.union(set2, dest: set3), 'should have 6 elements stored in the new set'
      assert_equal ::Set.new(%w[1 2 3 4 5 6]), set3.to_set, 'should return elements contained in either sets'

      assert_equal ::Set.new(set_contents), @set.to_set, 'should still be the same'
      assert_equal ::Set.new(set2_contents), set2.to_set, 'should still be the same'
    end

    def test_to_a
      values = %w[1 2 3]
      @set.add(*values)

      assert_equal @set.to_a.sort, values, 'should return an array containing the correct values'
    end

    def test_to_set
      values = %w[1 2 3]
      @set.add(*values)

      assert_equal ::Set.new(values), @set.to_set, 'should return the correct set'
    end

    def test_each
      values = %w[a b c d aa]
      @set.add(*values)

      missing = values.dup
      @set.each do |word|
        assert values.include?(word), 'should be in the values'
        missing.delete(word)
      end
      assert_empty missing, 'should not have missed anything'

      matched = ::Set.new
      @set.each(match: 'a*') { |word| matched << word }
      assert_equal ::Set.new(%w[a aa]), matched, 'should contain a and aa only'
    end
  end
end
