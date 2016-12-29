# frozen_string_literal: true
require 'digest'
require 'securerandom'
require 'test_helper'

module Redstruct
  module Utils
    class ScriptableTest < Redstruct::Test
      def test_defscript
        script = <<~LUA
          local sum = 0
          for i, key in ipairs(KEYS) do
            local value = tonumber(ARGV[i])
            redis.call("set", key, value)
            sum = sum + value
          end

          return sum
        LUA
        sha1 = Digest::SHA1.hexdigest(script)

        klass = Class.new(Redstruct::Factory::Object) do
          include Redstruct::Utils::Scriptable
          defscript :test, script
        end

        assert_equal({ script: script, sha1: sha1 }, klass::SCRIPT_TEST, 'should have defined the constant properly')

        factory = create_factory
        keys = [factory.string(SecureRandom.hex(4)).key, factory.string(SecureRandom.hex(4)).key]
        argv = [SecureRandom.random_number(10), SecureRandom.random_number(10)]
        assert_equal argv.reduce(&:+), klass.new(factory: factory).test(keys: keys, argv: argv)

        keys.each_with_index do |key, index|
          assert_equal argv[index], factory.string(key).get.to_i, 'script should have set the value properly'
        end
      end

      def test_const_defined
        klass = Class.new { include Redstruct::Utils::Scriptable }
        klass.const_set('SCRIPT_TEST', true)

        stdout, = capture_subprocess_io { klass.defscript('test', 'return 0') }
        assert_match(/WARN/, stdout, 'should produce a warning if the constant is already defined')
        refute klass.method_defined?('test')
        assert_equal true, klass::SCRIPT_TEST, 'should still be the old value'
      end

      def test_method_defined
        klass = Class.new do
          include Redstruct::Utils::Scriptable

          def test
            return true
          end
        end

        stdout, = capture_subprocess_io { klass.defscript('test', 'return 0') }
        assert_match(/WARN/, stdout, 'should produce a warning if the method is already defined')
        refute klass.const_defined?('SCRIPT_TEST')
        assert_equal true, klass.new.test, 'should still be the old value'
      end
    end
  end
end
