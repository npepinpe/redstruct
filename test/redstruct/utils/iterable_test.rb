# frozen_string_literal: true

require 'test_helper'

module Redstruct
  module Utils
    class IterableTest < Redstruct::TestCase
      def test_to_enum_bad_impl
        assert_raises(NotImplementedError, 'should fail and raise not implemented on missing implementations') do
          BadIterator.new.to_enum
        end
      end

      def test_each_bad_impl
        assert_raises(NotImplementedError, 'should fail and raise not implemented on missing implementations') do
          BadIterator.new.each { |o| o }
        end
      end

      def test_each_no_block
        iterator = self.class::Iterator.new
        enum = iterator.each # returns an enum

        assert_kind_of Enumerator, enum, 'should return an enumerator when called with no block'
        assert_equal 0, iterator.iterations, 'should not actually have been called ever yet'
      end

      def test_each_block
        iterator = self.class::Iterator.new
        ones = []

        iterator.each(max_iterations: 2) { |one| ones << one }
        assert_equal [1, 1], ones, 'should have returned an array of 2 "1"s'
      end

      # each does not do anything with match or count but pass them on to to_enum, so make sure that this is what we do
      def test_each_match_count
        iterator = self.class::Iterator.new
        _ = iterator.each(match: 'match', count: 1) # returns an enum

        assert_equal 'match', iterator.match, 'should have received the correct match param'
        assert_equal 1, iterator.count, 'should have received the correct count param'
      end

      def test_each_max_iterations
        iterator = self.class::Iterator.new
        enum = iterator.each(max_iterations: 10)

        assert_equal 10, enum.to_a.size, 'should iterate up to 10 times, therefore containing 10 "1"s in the array'
        assert_equal 10, iterator.iterations, 'should have iterated exactly 10 times'
      end

      def test_each_batch_size
        iterator = self.class::Iterator.new
        iterator.each(max_iterations: 2, batch_size: 2).each do |ones|
          assert_equal 2, ones.size, 'should yield in batches of 2 elements'
          assert_equal [1, 1], ones, 'should yield a list of 2 "1"s'
        end
      end

      # Sample class not implementing interface
      class BadIterator
        include Redstruct::Utils::Iterable
      end

      class Iterator
        include Redstruct::Utils::Iterable

        attr_reader :iterations, :match, :count

        def initialize
          @iterations = 0
          @match = nil
          @count = nil
        end

        # the idea is to return an infinite stream of 1s, but monitor how the enum was constructed, and how many
        # iterations were performed, as opposed to creating a mock object
        def to_enum(match: '*', count: 10)
          @match = match
          @count = count
          @iterations = 0

          return Enumerator.new do |yielder|
            loop do
              @iterations += 1 # increment before yielding, since yielding might immediately raise StopIteration, but we'll still have iterated once
              yielder << 1
            end
          end
        end
      end
    end
  end
end
