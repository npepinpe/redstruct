# frozen_string_literal: true

require 'redstruct/utils/atomic_counter'

module Redstruct
  # Base class for all Redstruct tests. Configures the gem, provides a default factory, and makes sure to clean it up
  # at the end
  class TestCase < Minitest::Test
    # rubocop: disable Style/ClassVars
    @@counter = Redstruct::Utils::AtomicCounter.new
    @@factory = Redstruct::Factory.new

    parallelize_me!
    make_my_diffs_pretty!

    # Use this helper to create a factory that the test class will keep track of and remove at the end
    def create_factory(namespace = nil)
      namespace ||= @@counter.increment.to_s
      return @@factory.factory(namespace)
    end

    # Helper when trying to ensure a particular redis-rb command was called
    # while still calling it. This allows for testing things outside of our
    # control (e.g. srandmember returning random items)
    # The reason we don't simply just mock the return value is to ensure
    # that tests will break if a command (e.g. srandmember) changes its return
    # value
    def ensure_command_called(object, command, *args, allow: true)
      mock = flexmock(object.connection).should_receive(command).with(object.key, *args)
      mock = mock.pass_thru if allow

      return mock
    end
  end
end
