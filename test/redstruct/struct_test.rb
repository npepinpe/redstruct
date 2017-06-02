# frozen_string_literal: true

require 'securerandom'
require 'test_helper'

module Redstruct
  class StructTest < Redstruct::TestCase
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
      refute @struct.expire_at(1), 'should return false since no existing key was expired'
      write_struct
      assert @struct.expire_at(1), 'should have correctly marked to key to be expired'
      refute @struct.exists?, 'should not exist since it was marked to be expired 1 second after 1970-01-01'
    end

    def test_persist
      refute @struct.persist, 'should not be able to persist non existent keys'
      write_struct
      refute @struct.persist, 'should not be able to persist keys with no expiry'

      @struct.expire(1)
      assert @struct.ttl.positive?, 'should now have a ttl'
      assert @struct.persist, 'should be able to persist keys with expiry'
      assert_nil @struct.ttl, 'should not have a ttl anymore'
    end

    def test_type
      assert_nil @struct.type, 'should have no type when it does not exist'

      # to avoid writing tests for each possible type, we simply ensure we return
      # whatever redis returned
      type = SecureRandom.hex(8)
      write_struct
      ensure_command_called(@struct, :type, allow: false).once.and_return(type)
      assert_equal type, @struct.type, 'should return whatever redis returns'
    end

    def test_ttl
      assert_nil @struct.ttl, 'should have no ttl initially'

      write_struct
      assert_nil @struct.ttl, 'should still have no ttl even if it exists'

      @struct.expire(1)
      assert @struct.ttl.positive?, 'should have a ttl > 0'

      @struct.persist
      assert_nil @struct.ttl, 'should now have no ttl again'
    end

    def test_dump; end

    def test_restore; end

    # a struct has no set value, so use the redis connection to "cheat" and set one so the struct actually exists
    def write_struct
      @struct.connection.set(@struct.key, 'foo')
    end
    private :write_struct
  end
end
