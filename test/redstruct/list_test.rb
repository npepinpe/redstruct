# frozen_string_literal: true

require 'test_helper'

module Redstruct
  class ListTest < Redstruct::Test
    def setup
      super
      @factory = create_factory
      @list = @factory.list('list')
    end

    def test_clear
      @list.append(1, 2, 3)
      refute @list.empty?, 'should not be empty'
      @list.clear
      assert @list.empty?, 'should be empty after a clear operation'
    end

    def test_empty?
      assert @list.empty?, 'should be initially empty'
      @list.push(1)
      refute @list.empty?, 'should not be empty anymore'
    end

    def test_brackets
      (0..2).each do |i|
        value = SecureRandom.hex(4)
        assert_nil @list[i], 'should return nothing initially'
        @list[i] = value
        assert_equal value, @list[i], 'should return the correct value'
      end
    end

    def test_insert_single
      initial = SecureRandom.hex(4)
      assert_raises(Redis::CommandError, 'should fail (out of bounds)') do
        @list.insert(initial, 1)
      end

      assert @list.insert(initial, 0), 'should insert correctly first element'
      assert_equal initial, @list[0]

      assert @list.insert(initial, 1), 'should insert correctly second element'
      assert_equal initial, @list[1]

      value = SecureRandom.hex(4)
      assert @list.insert(value, 1), 'should insert correctly between both'
      assert_equal value, @list[1], 'should have new value at index 1'
      assert_equal initial, @list[0], 'should still have correct value as index 0'
      assert_equal initial, @list[2], 'should still have correct value as index 2'
    end

    def test_append
      values = %w[1 2]
      assert_equal values.size, @list.append(*values), 'should have successfully appended'
      assert_equal values, @list.to_a, 'should have the correct values stored'

      appended = %w[3 4]
      expected = values + appended
      assert_equal expected.size, @list.append(*appended), 'should have successfully appended'
      assert_equal expected, @list.to_a, 'should have the correct values stored'
    end

    def test_append_exists
      values = %w[1 2]
      refute @list.append(*values, exists: true), 'should not append since the list does not exist'

      @list[0] = 'a'
      assert @list.append(*values, exists: true), 'should have appended once the list existed'
      assert_equal %w[a 1 2], @list.to_a, 'should contain correct values'
    end

    def test_append_max
      values = %w[1 2]
      assert @list.append(*values, max: 2), 'should append all elements'
      assert_equal values, @list.to_a, 'should append all elements'

      assert_equal 2, @list.append(3, max: 2), 'should still return the actual size of the list'
      assert_equal values, @list.to_a, 'should not have appended the last element'
    end

    def test_prepend
      values = %w[1 2]
      assert_equal values.size, @list.prepend(*values), 'should have successfully prepended'
      assert_equal values, @list.to_a, 'should have the correct values stored'

      prepended = %w[3 4]
      expected = prepended + values
      assert_equal expected.size, @list.prepend(*prepended), 'should have successfully prepended'
      assert_equal expected, @list.to_a, 'should have the correct values stored'
    end

    def test_prepend_exists
      values = %w[1 2]
      refute @list.prepend(*values, exists: true), 'should not prepend since the list does not exist'

      @list[0] = 'a'
      assert @list.prepend(*values, exists: true), 'should have prepended once the list existed'
      assert_equal %w[1 2 a], @list.to_a, 'should contain correct values'
    end

    def test_prepend_max
      values = %w[1 2]
      assert @list.prepend(*values, max: 2), 'should prepend all elements'
      assert_equal values, @list.to_a, 'should append all elements'

      assert_equal 2, @list.prepend(3, max: 2), 'should still return the actual size of the list'
      assert_equal %w[3 1], @list.to_a, 'should not have prepended the last element'
    end

    def test_pop_single
      assert @list.empty?, 'should be empty initially'
      @list.append('a', 'b')

      assert_equal 'b', @list.pop, 'should have popped the last element'
      assert_equal %w[a], @list.to_a, 'should have only one element left'
    end

    def test_pop_multiple
      assert @list.empty?, 'should be empty initially'
      @list.append('a', 'b', 'c')

      assert_equal %w[b c], @list.pop(2), 'should have popped the last 2 elements'
      assert_equal %w[a], @list.to_a, 'should have only one element left'
    end

    # TODO: not the ideal way to test this, but what would be a better way?
    def test_pop_timeout
      assert @list.empty?, 'should be empty initially'

      Thread.new do
        sleep 0.2
        @list.push('a', 'b')
      end

      assert_equal 'b', @list.pop(timeout: 3), 'should have returned the correct element'
      assert_raises(ArgumentError, 'should not allow timeout with size > 1') do
        @list.pop(5, timeout: 1)
      end
    end

    def test_shift_single
      assert @list.empty?, 'should be empty initially'
      @list.append('a', 'b')

      assert_equal 'a', @list.shift, 'should have shifted the first element'
      assert_equal %w[b], @list.to_a, 'should have only one element left'
    end

    def test_shift_multiple
      assert @list.empty?, 'should be empty initially'
      @list.append('a', 'b', 'c')

      assert_equal %w[a b], @list.shift(2), 'should have shifted the first 2 elements'
      assert_equal %w[c], @list.to_a, 'should have only one element left'
    end

    # TODO: not the ideal way to test this, but what would be a better way?
    def test_shift_timeout
      assert @list.empty?, 'should be empty initially'

      Thread.new do
        sleep 0.2
        @list.push('a', 'b')
      end

      assert_equal 'a', @list.shift(timeout: 3), 'should have returned the correct element'
      assert_raises(ArgumentError, 'should not allow timeout with size > 1') do
        @list.shift(5, timeout: 1)
      end
    end

    def test_remove_left
      @list.append('a', 'b', 'a', 'b', 'a', 'b')
      assert_equal 1, @list.remove('a', count: 1), 'should remove 1 element equal to the value from left'
      assert_equal %w[b a b a b], @list.to_a, 'should have removed first a only'
      assert_equal 2, @list.remove('b', count: 2), 'should remove both bs'
      assert_equal %w[a a b], @list.to_a, 'should have only the last b left'
    end

    def test_remove_right
      @list.append('a', 'b', 'a', 'b', 'a', 'b')
      assert_equal 1, @list.remove('a', count: -1), 'should remove 1 element equal to the value from the right'
      assert_equal %w[a b a b b], @list.to_a, 'should have removed last a only'
      assert_equal 2, @list.remove('b', count: -2), 'should remove the last 2 bs'
      assert_equal %w[a b a], @list.to_a, 'should have only the middle b left'
    end

    def test_remove_all
      @list.append('a', 'b', 'b', 'a')
      assert_equal 2, @list.remove('a', count: 0), 'should remove all elements equal to the given value'
      assert_equal %w[b b], @list.to_a, 'should have only the other values left'
    end

    def test_size
      assert_equal 0, @list.size, 'should have size 0 initially'
      @list.push(1, 2)
      assert_equal 2, @list.size, 'should have the same amount that was pushed'
    end

    def test_to_a
      expected = %w[a b c]
      assert_equal [], @list.to_a, 'should return empty array initially'
      @list.push(*expected)
      assert_equal expected, @list.to_a, 'should return what was pushed'
    end

    def test_slice_positive
      values = %w[a b c d e f g]
      assert_equal [], @list.slice, 'should return nothing initially'
      @list.push(*values)

      assert_equal values.slice(0, 1), @list.slice(start: 0, length: 1), 'should return the same as Array#slice'
      assert_equal values.slice(2, 3), @list.slice(start: 2, length: 3), 'should return the same as Array#slice'
    end

    def test_slice_negative
      values = %w[a b c d e f g]
      assert_equal [], @list.slice, 'should return nothing initially'
      @list.push(*values)

      assert_equal values, @list.slice(start: 0, length: -1), 'should return the same as Array#slice'
      assert_equal values[2..-2], @list.slice(start: 2, length: -2), 'should return the same as Array#slice'
    end

    # Blocking is not tested as I'm still unsure what's a good way to test it
    def test_popshift
      assert_raises(ArgumentError, 'should not be able to push on something that is not a list') do
        @list.popshift(2)
      end

      values = %w[a b c]
      list2 = @factory.list('list2')

      @list.push(*values)
      assert_equal 'c', @list.popshift(list2), 'should have popped the last element'
      assert_equal %w[c], list2.to_a, 'should contain the popped element'

      assert_equal 'b', @list.popshift(list2), 'should have popped the last element'
      assert_equal %w[b c], list2.to_a, 'should contain the new popped element as its first element'
    end
  end
end
