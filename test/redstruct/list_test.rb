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
      assert_nil @list[0], 'should return nothing initially'
      @list[0] = 'a'
      assert_equal 'a', @list[0], 'should return the correct value'
    end
  end
end
