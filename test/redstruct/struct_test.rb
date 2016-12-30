# frozen_string_literal: true
require 'securerandom'
require 'test_helper'

module Redstruct
  class StructTest < Redstruct::Test
    def setup
      super
      @factory = create_factory
      @struct = @factory.struct('struct')
    end

    def test_initialize
      key = @factory.prefix(SecureRandom.hex(4))
      struct = Redstruct::Struct.new(key: key, factory: @factory)
      assert_equal key, struct.key, 'should have key unchanged after initialization'
    end

    def test_exists?
      refute @struct.exists?, 'struct should not yet exist'
      write_struct
      assert @struct.exists?, 'struct should exist if underlying redis key exists'
    end

    def test_delete
      refute @struct.delete, 'should return false since the struct did not exist'
      write_struct
      assert @struct.delete, 'should return true since a key was actually deleted'
    end

    def test_expire
      refute @struct.expire(1), 'should return false since no existing key was expired'
      write_struct
      assert @struct.expire(1), 'should have correctly expired the existing key'
    end

    def test_expire_at
    end

    def test_persist
    end

    def test_type
    end

    def test_ttl
    end

    def test_dump
    end

    def test_restore
    end

    # a struct has no set value, so use the redis connection to "cheat" and set one so the struct actually exists
    def write_struct
      @struct.connection.set(@struct.key, 'foo')
    end
    private :write_struct
  end
end
