# frozen_string_literal: true

require 'test_helper'

module Redstruct
  class ScriptTest < Redstruct::Test
    def setup
      super
      Redstruct.config.default_connection.with { |c| c.script(:flush) }

      @code = 'return 1'
      @factory = create_factory
      @script = @factory.script(@code)
    end

    def test_initialize
      assert_equal @code, @script.script, 'should have correct script'
      assert_equal Digest::SHA1.hexdigest(@code), @script.sha1, 'should have correct sha1'
      assert_equal @factory.connection, @script.connection, 'should have correct connection'

      script = @factory.script(@code, sha1: 'dummy sha1')
      assert_equal 'dummy sha1', script.sha1, 'should have accepted our dummy sha1 even if incorrect'
    end

    def test_script=
      lua = 'return 0'
      old_sha1 = @script.sha1
      new_sha1 = Digest::SHA1.hexdigest(lua)

      @script.script = lua
      assert_equal lua, @script.script, 'should have correctly assigned the new code'
      assert_equal new_sha1, @script.sha1, 'should have updated the sha1'
      refute_equal old_sha1, @script.sha1, 'should have a different sha1 now'
    end

    def test_exists?
      refute @script.exists?, 'should not initially exists'
      @script.load
      assert @script.exists?, 'script should exists after loading it'
    end

    def test_load
      refute @script.exists?, 'should not initially exists'
      assert_equal @script.sha1, @script.load, 'should return the sha1 of the script'
      assert @script.exists?, 'should exist after load'
    end

    def test_eval
      refute @script.exists?, 'should not exist initially'
      assert_equal 1, @script.eval, 'should execute the script (which returns 1)'
      assert @script.exists?, 'should exist after first evaluation'
    end
  end
end
