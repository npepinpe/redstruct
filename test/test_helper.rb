# frozen_string_literal: true

# Environment
ci_build = ENV['CI_BUILD'].to_i.positive?
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

# Bundler setup
require 'bundler/setup'
bundler_groups = %i[default test]
bundler_groups << (ci_build ? :ci : :debug)
Bundler.require(*bundler_groups)

# Default Redstruct config
require 'redstruct/all'
Redstruct.config.default_namespace = "redstruct:test:#{SecureRandom.uuid}"
Redstruct.config.default_connection = ConnectionPool.new(size: 5, timeout: 2) do
  Redis.new(host: ENV.fetch('REDIS_HOST', '127.0.0.1'), port: ENV.fetch('REDIS_PORT', 6379).to_i, db: ENV.fetch('REDIS_DB', 0).to_i)
end

# Setup Minitest
require 'minitest/autorun'
require 'flexmock/minitest'
require 'minitest/reporters'
Minitest::Reporters.use!([Minitest::Reporters::SpecReporter.new])
Minitest.after_run do
  Redstruct.config.default_connection.with do |conn|
    conn.flushdb
    conn.script(:flush)
  end
end

# Require everything else
require 'securerandom'
require 'helpers/test_case'
