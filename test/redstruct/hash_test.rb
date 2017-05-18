# frozen_string_literal: true

require 'test_helper'

module Redstruct
  class HashTest < Redstruct::Test
    def setup
      super
      @factory = create_factory
      @hash = @factory.hashmap('hash')
    end

    def test_brackets
      value = SecureRandom.hex(4)
      assert_nil @hash['test'], 'should return nil for non-existent element'
      @hash['test'] = value
      assert_equal value, @hash['test'], 'should return the correct value'
    end

    def test_get_one
      value = SecureRandom.hex(4)
      assert_nil @hash.get('a'), 'should return nil for non-existent element'
      @hash['a'] = value
      assert_equal value, @hash.get('a'), 'should return correct value'
    end

    def test_get_multiple
      hash = { 'a' => SecureRandom.hex(4), 'b' => SecureRandom.hex(4) }
      assert_equal({}, @hash.get('a', 'b'), 'should return a empty hash for non existent keys')
      @hash.update(hash)
      assert_equal hash, @hash.get('a', 'b'), 'should return the correct hash for requested keys'
    end

    def test_set
      value = SecureRandom.hex(4)
      assert_nil @hash['a'], 'should return nothing'
      @hash.set('a', value)
      assert_equal value, @hash['a'], 'should return the correct value'
    end

    def test_set_overwrite
      initial = SecureRandom.hex(4)
      updated = SecureRandom.hex(4)

      @hash.set('a', initial)
      @hash.set('a', updated, overwrite: false)
      assert_equal initial, @hash['a'], 'should not have overwritten the initial value'
      @hash.set('a', updated, overwrite: true)
      assert_equal updated, @hash['a'], 'should have overwritten the initial value'
    end

    def test_update
      initial = { 'a' => SecureRandom.hex(4), 'b' => SecureRandom.hex(4) }
      assert @hash.empty?, 'initial should be empty'
      @hash.update(initial)
      assert_equal initial, @hash.to_h, 'should have been updated accordingly'

      updated = { 'a' => SecureRandom.hex(4), 'c' => SecureRandom.hex(4) }
      @hash.update(updated)
      assert_equal initial.merge(updated), @hash.to_h, 'should have been updated correctly'
    end

    def test_empty?
      assert @hash.empty?, 'should initially be empty'
      @hash['a'] = 1
      refute @hash.empty?, 'should not be empty with one element'
    end

    def test_remove
      @hash['a'] = 'a'
      assert @hash.key?('a'), 'should contain something for key a'
      @hash.remove('a')
      refute @hash.key?('a'), 'should not contain the key a anymore'
    end

    def test_key?
      refute @hash.key?('a'), 'should not contain the key a initially'
      @hash['a'] = 1
      assert @hash.key?('a'), 'should now contain the key a'
    end

    def test_increment
    end

    def test_decrement
    end

    def test_keys
    end

    def test_values
    end

    def test_to_h
    end

    def test_size
    end

    def test_each
    end
  end
end
