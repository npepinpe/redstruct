# frozen_string_literal: true

require 'test_helper'

module Redstruct
  class FactoryTest < Redstruct::Test
    def test_initialize_default
      flexmock(Redstruct::ConnectionProxy).should_receive(:new).with(Redstruct.config.default_connection).once.pass_thru
      factory = Redstruct::Factory.new

      refute_nil factory.connection, 'should have the default connection when none provided'
      assert_equal Redstruct.config.default_namespace, factory.namespace, 'should be the default namespace if none provided'
    end

    def test_initialize_params
      namespace = 'test'
      connection = Redstruct::ConnectionProxy.new(ConnectionPool.new(size: 1, timeout: 1) {}) # for the purpose of the test, does not matter what the pool creates
      factory = Redstruct::Factory.new(connection: connection, namespace: namespace)

      assert_equal namespace, factory.namespace, 'should have assigned the correct namespace'
      assert_kind_of Redstruct::ConnectionProxy, factory.connection, 'should have properly constructed the proxy'
    end

    def test_initialize_no_proxy
      assert_raises(ArgumentError, 'should fail when no connection proxy given') { Redstruct::Factory.new(connection: 'test') }
    end

    def test_prefix_no_namespace
      factory = Redstruct::Factory.new(namespace: '')
      assert_equal 'key', factory.prefix('key'), 'should not namespace when namespace is blank string'
    end

    def test_prefix
      factory = Redstruct::Factory.new(namespace: 'test')
      assert_equal 'test:key', factory.prefix('key'), 'should correctly prefix the key with a namespace'
      assert_equal 'test:key', factory.prefix('test:key'), 'should not prefix an already prefixed key'
      assert_equal 'test:testkey', factory.prefix('testkey'), 'should prefix even if the key starts with the namespace (but is not separated by a colon)'
    end

    def test_to_enum
      factory, keys = populated_factory
      enum = factory.to_enum
      # wrap in set since we don't care about the ordering, and the redis scan command can theoretically return a key
      # more than once
      assert_equal ::Set.new(keys), ::Set.new(enum.to_a), 'Should retrieve all keys'
    end

    def test_to_enum_match
      factory, keys = populated_factory

      expected_key = keys[0]
      pattern = expected_key + '*'

      enum = factory.to_enum(match: pattern)
      retrieved = enum.to_a
      assert_equal 1, retrieved.size, 'should have retrieved only one key'
      assert_equal expected_key, retrieved[0], 'should have retrieved the correct key'
    end

    def test_delete
      factory, = populated_factory
      keys_matcher = factory.prefix('*')

      refute_empty factory.connection.keys(keys_matcher), 'should have at least one key in the factory, otherwise test is pointless'
      factory.delete
      assert_empty factory.connection.keys(keys_matcher), 'should have no more keys in the factory'
    end

    def test_script
      factory = create_factory
      script = factory.script('return 0')
      assert_kind_of Redstruct::Script, script, 'should always return a script object'
      assert_equal 0, script.eval, 'should execute script correctly'
      assert_equal factory.connection, script.connection, 'script and factory should share the same connection'
    end

    def test_factory
      factory = create_factory
      sub_factory = factory.factory('sub')

      assert sub_factory.namespace.start_with?(factory.namespace), 'should be prefixed with parent factory namespace'
      assert_equal factory.connection, sub_factory.connection, 'should share the same connection'
    end

    def test_lock
      factory1 = create_factory
      lock1 = factory1.lock('res')
      assert_kind_of Redstruct::Lock, lock1, 'should always return a Redstruct::Lock'

      factory2 = create_factory
      lock2 = factory2.lock('res')

      assert lock1.acquire, 'should be able to acquire free lock'
      assert lock2.acquire, 'should be able to acquire lock for the a resource with the same name but living in a different factory (i.e. not the same resource!)'
      refute factory1.lock('res').acquire, 'should not be able to acquire lock on pre-acquired resource'
    end

    def test_hashmap
      factory = create_factory
      assert_struct_method(:hashmap, Redstruct::Hash, factory)
    end

    def test_structs
      factory = create_factory
      %w[Counter List Set SortedSet String Struct].each do |struct|
        method = struct.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
        type = Redstruct.const_get(struct)
        assert_struct_method(method, type, factory)
      end
    end

    def assert_struct_method(method, type, factory)
      assert Redstruct::Factory.method_defined?(method), "factory should have a method for #{type} named #{method}"

      object = factory.public_send(method, 'key')
      assert_equal factory.prefix('key'), object.key, 'object key should be namespaced under the factory namespace'
      assert_equal factory, object.factory
      assert_kind_of type, object, "factory method #{method} should always return an object of type #{type}"
    end
    private :assert_struct_method

    def populated_factory
      factory = create_factory

      # populate between 2 and 10 objects, random keys, random values
      objects = Array.new(SecureRandom.random_number(9) + 2) do
        object = factory.string(SecureRandom.hex(4))
        object.set(SecureRandom.hex(4))
        object
      end

      return factory, objects.map(&:key)
    end
    private :populated_factory
  end
end
