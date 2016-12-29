# frozen_string_literal: true
require 'test_helper'
require 'securerandom'
require 'flexmock/minitest'
require 'pry'

module Redstruct
  # TODO: not quite sure if this test suite is good enough
  class ConnectionProxyTest < Redstruct::Test
    def test_initialize
      assert_raises(ArgumentError, 'should fail to initialize without a proxy object') { Redstruct::ConnectionProxy.new }
    end

    def test_connection
      proxy = connection_proxy(redis_connection)
      assert_equal 'PONG', proxy.ping, 'Should correctly execute the ping command using the given redis connection'
    end

    def test_connection_pool
      proxy = connection_proxy
      assert_equal 'PONG', proxy.ping, 'Should correctly execute the ping command using the given connection pool'
    end

    def test_with
      proxy = connection_proxy
      proxy.with do |connection|
        assert_kind_of Redis, connection, 'should have yielded a redis connection'
        proxy.with do |new_connection|
          assert_equal connection, new_connection, 'calling with from within a with block should return the same connection'
        end
      end

      connection = redis_connection
      proxy = connection_proxy(connection)
      proxy.with do |new_connection|
        assert_equal connection, new_connection, 'calling with when proxying a single connection should return that connection'
      end
    end

    # it is easier to test with a mocked redis connection than with a connection pool, and as far as I can tell, has
    # no downsides
    def test_proxied_methods
      connection = flexmock(redis_connection)
      proxy = connection_proxy(connection)

      proxied_methods = Redis.public_instance_methods(false) - Redstruct::ConnectionProxy::NON_COMMAND_METHODS
      proxied_methods.each do |method|
        retval = SecureRandom.hex(8)
        args = generate_random_args
        connection.should_receive(method).with(*args, Proc).and_return(retval).once
        assert_equal retval, proxy.public_send(method, *args) {}, "#{method} should be proxied with the correct arguments and block"
      end

      # flexmock automatically verifies all expected calls were matched
    end

    def test_method_missing
      connection = flexmock(redis_connection)
      proxy = connection_proxy(connection)

      method = '__strange_method__'
      connection.should_receive(method).and_return(42)
      assert_equal 42, proxy.public_send(method), 'Should proxy even missing methods to the connection object'
    end

    def test_respond_to_missing?
      assert connection_proxy.respond_to?('__strange_method__'), 'Redis class responds to all missing method, and so should ConnectionProxy'
    end

    def connection_proxy(connection = nil)
      connection ||= Redstruct.config.default_connection
      return Redstruct::ConnectionProxy.new(connection)
    end

    # obtain a plain redis connection
    def redis_connection
      return Redstruct.config.default_connection.with { |c| c }.dup
    end
    private :redis_connection

    def generate_random_args
      argc = SecureRandom.random_number(10) + 1
      return Array.new(argc) { SecureRandom.hex(4) }
    end
    private :generate_random_args
  end
end
