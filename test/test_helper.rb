# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'securerandom'
require 'bundler/setup'
require 'redstruct/all'
require 'minitest/autorun'

# Default Redstruct config
Redstruct.config.namespace = 'redstruct'
Redstruct.config.connection_pool = ConnectionPool.new(size: 2, timeout: 5) do
  Redis.new(
    host: ENV.fetch('REDIS_HOST', '127.0.0.1'),
    port: ENV.fetch('REDIS_PORT', 6379).to_i,
    db: ENV.fetch('REDIS_DB', 0).to_i
  )
end

module Redstruct
  # Base class for all Redstruct tests. Configures the gem, provides a default factory, and makes sure to clean it up
  # at the end
  class Test < Minitest::Test
    parallelize_me!
    make_my_diffs_pretty!

    def initialize(*args)
      super
      @factories = {}
    end

    # Clear previous factories
    def setup
      @factories.keys.each { |name| Redstruct.delete(name, clear: true) }
      @factories.clear
    end

    # Use this helper to create a factory that the test class will keep track of and remove at the end
    def create_factory(name = nil)
      name ||= SecureRandom.uuid
      @factories[name] = Redstruct.make(name: name)
    end
  end
end
