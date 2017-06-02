# frozen_string_literal: true

require 'test_helper'

module Redstruct
  class SortedTest < Redstruct::TestCase
    def setup
      super
      @factory = create_factory
      @set = @factory.sorted_set('zset')
    end

    def test_initialize
      refute @set.lexicographic?, 'should not be a lexicographically sorted set'

      lex = @factory.sorted_set('lzset', lex: true)
      assert lex.lexicographic?, 'should be marked as a lexicographically sorted set'
    end

    def test_clear
      assert @set.empty?, 'should initially be empty'
      @set.add(1, 'a')
      refute @set.empty?, 'should not be empty'

      assert @set.clear, 'should have been cleared'
      assert @set.empty?, 'should now be empty again'
    end

    def test_empty?
      assert @set.empty?, 'should be empty initially'
      @set.add(1, 'a')
      refute @set.empty?, 'should now not be empty'
    end

    def test_add
      values = { 1 => 'a', 2 => 'c', 3 => 'b' }
      assert_equal 3, @set.add(*values.keys.zip(values.values)), 'should have added 3 items'
      assert_equal 0, @set.add(1, 'a'), 'should not add pre-existing value'
      assert_equal ::Set.new(%w[a b c]), @set.to_set, 'should contain exactly the values added'
    end

    def test_add_exists
      assert_equal 0, @set.add([1, 'a'], exists: true), 'should not have added anything items'
      assert @set.empty?, 'should not contain anything'

      @set.add([2, 'a'])
      assert_equal 2.0, @set.score('a'), 'should have score of 2'
      assert_equal 1, @set.add([1, 'a'], exists: true), 'should have added 1 element'
      assert_equal 1.0, @set.score('a'), 'should have score of 1'
    end

    def test_add_overwrite
      @set.add([2, 'b'])
      assert_equal 0, @set.add([3, 'b'], overwrite: false), 'should not overwrite pre-existing value'
      assert_equal 2.0, @set.score('b'), 'should still have old score'
      assert_equal 1, @set.add([3, 'b'], overwrite: true), 'should have overwritten pre-existing value'
      assert_equal 3.0, @set.score('b'), 'should now have score of 3'
    end

    def test_add_lex
      set = @factory.sorted_set('zset', lex: true)
      assert_equal 2, set.add([1, 'c'], [2, 'd']), 'should have added 2 elements'
      assert_equal 2, set.add('a', 'b'), 'should have added 2 elements'

      assert_equal %w[a b c d], set.to_a, 'should be lexicographically sorted'
      %w[a b c d].each do |letter|
        assert_equal 0.0, set.score(letter), 'should have a score of 0'
      end
    end

    def test_increment
      assert_equal 1.0, @set.increment('a'), 'should have a default score of 1.0'
      assert_equal 3.0, @set.increment('a', by: 2.0), 'should have incremented the score by 2'
      assert_equal 3.0, @set.score('a'), 'should have the correct score of 3.0'
    end

    def test_increment_lex
      set = @factory.sorted_set('zset', lex: true)
      assert_raises(NotImplementedError, 'should not be able to increment scores for lexicographic sets') do
        set.increment('a')
      end
    end

    def test_decrement
      assert_equal(-1.0, @set.decrement('a'), 'should have a default score of -1.0')
      assert_equal(-3.0, @set.decrement('a', by: 2.0), 'should have decremented the score by 2')
      assert_equal(-3.0, @set.score('a'), 'should have the correct score of -3.0')
    end

    def test_decrement_lex
      set = @factory.sorted_set('zset', lex: true)
      assert_raises(NotImplementedError, 'should not be able to decrement scores for lexicographic sets') do
        set.decrement('a')
      end
    end

    def test_size
      assert_equal 0, @set.size, 'should have a size of 0 initially'
      @set.add([1, 'a'], [2, 'b'], [3, 'c'])
      assert_equal 3, @set.size, 'should have a size of 3'
    end

    # The slice structure has its own tests, so we only test the creation of
    # a slice here.
    def test_slice
      slice = @set.slice
      assert_equal @set.key, slice.key, 'should have the same object key'
      assert_equal @set.factory, slice.factory, 'should have the same initial factory'
      assert_equal '-inf', slice.lower, 'should have infinity as lower bound'
      assert_equal '+inf', slice.upper, 'should have infinity as upper bound'
      refute slice.exclusive, 'should not be exclusive by default'

      slice = @set.slice(lower: 1, upper: 3, exclusive: true)
      assert_equal '(1.0', slice.lower, 'should have exclusive 1.0 as lower bound'
      assert_equal '(3.0', slice.upper, 'should have exclusive 3.0 as upper bound'

      slice = @set.slice(lower: 1, upper: 3, exclusive: false)
      assert_equal 1.0, slice.lower, 'should have inclusive 1.0 as lower bound'
      assert_equal 3.0, slice.upper, 'should have inclusive 3.0 as upper bound'
    end

    def test_slice_lex
      set = @factory.sorted_set('zset', lex: true)
      slice = set.slice
      assert slice.lex, 'should be a lexicographical slice'
      assert_equal '-', slice.lower, 'should have lex infinity as lower bound'
      assert_equal '+', slice.upper, 'should have lex infinity as upper bound'

      slice = set.slice(lower: 'a', upper: 'd', exclusive: true)
      assert_equal '(a', slice.lower, 'should have exclusive lower bound a'
      assert_equal '(d', slice.upper, 'should have exclusive upper bound d'

      slice = set.slice(lower: 'a', upper: 'd', exclusive: false)
      assert_equal '[a', slice.lower, 'should have inclusive lower bound a'
      assert_equal '[d', slice.upper, 'should have inclusive upper bound d'
    end

    def test_contain?
      refute @set.contain?('a'), 'should not contain a initially'
      @set.add([1, 'a'])
      assert @set.contain?('a'), 'should now contain a'
    end

    def test_index
      assert_nil @set.index('a'), 'should not return any index initially'
      @set.add([2, 'b'], [1, 'a'])
      assert_equal 0, @set.index('a'), 'should return correct index for a'
      assert_equal 1, @set.index('b'), 'should return correct index for b'
    end

    def test_rindex
      assert_nil @set.rindex('a'), 'should not return any index initially'
      @set.add([2, 'b'], [1, 'a'])
      assert_equal 1, @set.rindex('a'), 'should return correct index for a'
      assert_equal 0, @set.rindex('b'), 'should return correct index for b'
    end

    def test_score
      assert_nil @set.score('a'), 'should return nil when item not in the set'
      @set.add([1, 'a'])
      assert_equal 1.0, @set.score('a'), 'should return the correct score'
    end

    def test_remove
      items = %w[a b c]
      assert_equal 0, @set.remove(*items), 'should not have removed anything'

      @set.add(*[1, 2, 3].zip(items))
      @set.add([4, 'd'])
      assert_equal 1, @set.remove('d', 'e'), 'should only remove 1 element'
      assert_equal items, @set.to_a, 'should contain the correct elements'
      assert_equal 3, @set.remove(*items), 'should have removed all 3 elements'
      assert @set.empty?, 'should be empty now'
    end

    def test_to_a
      assert_empty @set.to_a, 'should initially return an empty array'
      @set.add([4, 'a'], [3, 'b'], [2, 'c'], [1, 'd'])
      assert_equal %w[d c b a], @set.to_a, 'should return a sorted array'
    end

    def test_to_set
      items = %w[a b]
      assert_equal ::Set.new, @set.to_set, 'should return an empty set'
      @set.add(*[1, 2].zip(items))
      assert_equal ::Set.new(items), @set.to_set, 'should return a set containing the elements'
    end

    def test_each
      values = %w[aa b c d a]
      scores = %w[1 2 3 4 5]
      sorted = scores.zip(values).sort_by { |pair| pair[0].to_i }
      @set.add(*sorted)

      received = []
      @set.each do |word|
        assert values.include?(word), 'should be in the values'
        received << word
      end
      assert_equal received, @set.to_a, 'should have received it all in order'

      received = []
      @set.each(match: 'a*') { |word| received << word }
      assert_equal %w[aa a], received, 'should contain a and aa only'
    end

    def test_each_with_scores
      values = %w[aa b c d a]
      scores = %w[1 2 3 4 5].map(&:to_f)
      sorted = scores.zip(values).sort_by { |pair| pair[0].to_i }
      @set.add(*sorted)

      @set.each(with_scores: true).each_with_index do |(value, score), index|
        assert_equal values[index], value, 'should receive the correct value'
        assert_equal scores[index], score, 'should receive the correct score'
      end
    end
  end
end
