# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'securerandom'
require 'monitor'
require 'bundler/setup'
require 'redstruct/all'
require 'minitest/autorun'
require 'flexmock/minitest'

Bundler.require(:default, :test)

if ENV['CI_BUILD'].to_i == 1
  require 'codacy-coverage'
  Codacy::Reporter.start
end

# Default Redstruct config
Redstruct.config.default_namespace = "redstruct:test:#{SecureRandom.uuid}"
Redstruct.config.default_connection = ConnectionPool.new(size: 5, timeout: 2) do
  Redis.new(host: ENV.fetch('REDIS_HOST', '127.0.0.1'), port: ENV.fetch('REDIS_PORT', 6379).to_i, db: ENV.fetch('REDIS_DB', 0).to_i)
end

# Setup cleanup hook
Minitest.after_run do
  Redstruct.config.default_connection.with do |conn|
    conn.flushdb
    conn.script(:flush)
  end
end

# Small class used to generate thread-safe sequence when creating per-test
# factories
class AtomicInteger
  def initialize
    @lock = Mutex.new
    @current = 0
  end

  def incr
    value = nil
    @lock.synchronize do
      value = @current
      @current += 1
    end

    return value
  end
end

module Redstruct
  # Base class for all Redstruct tests. Configures the gem, provides a default factory, and makes sure to clean it up
  # at the end
  class Test < Minitest::Test
    @@counter = AtomicInteger.new # rubocop: disable Style/ClassVars

    parallelize_me!
    make_my_diffs_pretty!

    # Use this helper to create a factory that the test class will keep track of and remove at the end
    def create_factory(namespace = nil)
      namespace ||= "#{Redstruct.config.default_namespace}:#{@@counter.incr}"
      return Redstruct::Factory.new(namespace: namespace)
    end
  end
end
