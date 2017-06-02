# frozen_string_literal: true

require 'test_helper'

module Redstruct
  class CounterTest < Redstruct::TestCase
    def setup
      super
      @factory = create_factory
      @counter = @factory.counter('counter')
      @ring = @factory.counter('ring', max: 4)
      @pair = @factory.counter('pair', by: 2)
    end

    def test_initialize
      assert_equal 1, @counter.default_increment, 'should have default increment'
      assert_nil @counter.max, 'should have no maximum value by default'

      assert_equal 2, @pair.default_increment, 'should increment by 2'
      assert_nil @pair.max, 'should have no maximum value'

      assert_equal 1, @ring.default_increment, 'should have a default increment'
      assert_equal 4, @ring.max, 'should have a maximum value'
    end

    def test_get
      assert_equal 0, @counter.get, 'initial value is always nil'
      @counter.set(1)
      assert_equal 1, @counter.get, 'should be now be equal to 1'
    end

    def test_set
      assert_equal 0, @counter.get, 'initial value is always nil'
      assert @counter.set(2), 'should return true has it has been set'
      assert_equal 2, @counter.get, 'should be now be equal to 2 after a set'
    end

    def test_getset
      assert_equal 0, @counter.getset(2), 'should return the old value (0)'
      assert_equal 2, @counter.getset(4), 'should return the old value (2)'
      assert_equal 4, @counter.get, 'should return the current value'
    end

    def test_increment
      assert_equal 1, @counter.increment, 'should increment by 1 and return the value'
      assert_equal 2, @counter.increment, 'should increment by 1 and return the value'

      assert_equal 2, @pair.increment, 'should increment by 2 and return the value'
      assert_equal 4, @pair.increment, 'should increment by 2 and return the value'
    end

    def test_increment_by
      assert_equal 2, @counter.increment(by: 2), 'should increment by 2 and return the new value'
      assert_equal 3, @counter.increment, 'should increment by 1 and return the new value'

      assert_equal 3, @pair.increment(by: 3), 'should increment by 3 and return the new value'
      assert_equal 5, @pair.increment, 'should increment by 2 and return the new value'

      assert_equal 2, @ring.increment(by: 2), 'should increment by 2 and return the new value'
      assert_equal 3, @ring.increment, 'should increment by 1 and return the new value'
    end

    def test_increment_ring
      assert_equal 2, @counter.increment(by: 2, max: 3), 'should increment by 2 and return the new value'
      assert_equal 0, @counter.increment(max: 3), 'should increment by 1, cycle around, and return the new value'

      assert_equal 0, @pair.increment(max: 2), 'should increment by 2, cycle around, and return the new value'
      assert_equal 0, @pair.increment(max: 2), 'should increment by 2, cycle around, and return the new value'

      assert_equal 2, @ring.increment(by: 2), 'should increment by 2 and return the new value'
      assert_equal 0, @ring.increment(by: 2), 'should increment by 2, cycle around, and return the new value'
      assert_equal 1, @ring.increment(by: 5), 'should increment by 2, cycle around, and return the new value'
      assert_equal 6, @ring.increment(by: 5, max: 7), 'should increment by 2, cycle around, and return the new value'
    end

    def test_decrement
      assert_equal(-1, @counter.decrement, 'should decrement by 1 and return the value')
      assert_equal(-2, @counter.decrement, 'should decrement by 1 and return the value')

      assert_equal(-2, @pair.decrement, 'should decrement by 2 and return the value')
      assert_equal(-4, @pair.decrement, 'should decrement by 2 and return the value')
    end

    def test_decrement_by
      assert_equal(-2, @counter.decrement(by: 2), 'should decrement by 2 and return the new value')
      assert_equal(-3, @counter.decrement, 'should decrement by 1 and return the new value')

      assert_equal(-3, @pair.decrement(by: 3), 'should decrement by 3 and return the new value')
      assert_equal(-5, @pair.decrement, 'should decrement by 2 and return the new value')

      assert_equal(-2, @ring.decrement(by: 2), 'should decrement by 2 and return the new value')
      assert_equal(-3, @ring.decrement, 'should decrement by 1 and return the new value')
    end

    def test_decrement_ring
      assert_equal(-2, @counter.decrement(by: 2, max: 3), 'should decrement by 2 and return the new value')
      assert_equal 0, @counter.decrement(max: 3), 'should decrement by 1, cycle around, and return the new value'

      assert_equal 0, @pair.decrement(max: 2), 'should decrement by 2, cycle around, and return the new value'
      assert_equal 0, @pair.decrement(max: 2), 'should decrement by 2, cycle around, and return the new value'

      assert_equal(-2, @ring.decrement(by: 2), 'should decrement by 2 and return the new value')
      assert_equal 0, @ring.decrement(by: 2), 'should decrement by 2, cycle around, and return the new value'
      assert_equal(-1, @ring.decrement(by: 5), 'should decrement by 2, cycle around, and return the new value')
      assert_equal(-6, @ring.decrement(by: 5, max: 7), 'should decrement by 2, cycle around, and return the new value')
    end
  end
end
