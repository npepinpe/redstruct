# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'securerandom'
require 'bundler/setup'
require 'redstruct/all'
require 'minitest/autorun'

Bundler.require(:default, :test)

# Default Redstruct config
Redstruct.config.default_namespace = 'redstruct:test'
Redstruct.config.default_connection = ConnectionPool.new(size: 5, timeout: 2) do
  Redis.new(host: ENV.fetch('REDIS_HOST', '127.0.0.1'), port: ENV.fetch('REDIS_PORT', 6379).to_i, db: ENV.fetch('REDIS_DB', 0).to_i)
end

module Redstruct
  # Base class for all Redstruct tests. Configures the gem, provides a default factory, and makes sure to clean it up
  # at the end
  class Test < Minitest::Test
    parallelize_me!
    make_my_diffs_pretty!

    # Clear previous factories
    def setup
      @factories = []
    end

    def teardown
      @factories.each(&:delete)
      @factories.clear
    end

    # Use this helper to create a factory that the test class will keep track of and remove at the end
    def create_factory(namespace = nil)
      namespace ||= "#{Redstruct.config.default_namespace}:#{SecureRandom.hex(8)}"
      @factories << Redstruct::Factory.new(namespace: namespace)
      return @factories.last
    end
  end
end
