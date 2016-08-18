require 'securerandom'

module Restruct
  module Types
    class Lock < Restruct::Types::Base
      include Restruct::Utils::Scriptable

      # SCRIPTS
      ACQUIRE_SCRIPT = <<~LUA
      local token = ARGV[1]
      local expiry = tonumber(ARGV[2])

      redis.call('set', KEYS[1], token, 'NX')
      if redis.call('get', KEYS[1]) == token then
        redis.call('expire', KEYS[1], expiry)
        return token
      end

      return false
      LUA

      RELEASE_SCRIPT = <<~LUA
      local currentToken = ARGV[1]
      local nextToken = ARGV[2]
      local expiry = tonumber(ARGV[3])

      if redis.call('get', KEYS[1]) == currentToken then
        redis.call('set', KEYS[1], nextToken, 'EX', expiry)
        redis.call('lpush', KEYS[2], nextToken)
        redis.call('expire', KEYS[2], expiry)
        return true
      end

      return false
      LUA
      # SCRIPTS

      DEFAULT_EXPIRY = 10 # seconds
      DEFAULT_TIMEOUT = nil # milliseconds; nil means do not block

      attr_reader :token

      # @param [Integer] In seconds; to prevent infinite locking, each mutex is released after a certain expiry time
      # @param [Integer] In seconds; if > 0, will block for this amount of time when trying to obtain the lock
      def initialize(expiry: DEFAULT_EXPIRY, timeout: DEFAULT_TIMEOUT, **options)
        super(**options)

        @token = nil
        @expiry = expiry
        @timeout = timeout.to_i

        create do |factory|
          @lease = factory.string('lease')
          @tokens = factory.list('tokens')
        end
      end

      def locked
        yield if acquire
      ensure
        release
      end

      def blocking?
        return @timeout > 0
      end

      def acquire
        acquired = false
        token = non_blocking_acquire(@token)
        token = blocking_acquire if token.nil? && blocking?

        unless token.nil?
          @token = token
          acquired = true
        end

        return acquired
      end

      def release
        return false if @token.nil?
        return release_script(@token)
      end

      def acquire_script(token)
        return script(ACQUIRE_SCRIPT, id: "#{self.class.name}#acquire", keys: @lease.key, values: [token, @expiry])
      end
      private :acquire_script

      def release_script(token)
        next_token = SecureRandom.uuid
        return script(RELEASE_SCRIPT, id: "#{self.class.name}#release", keys: [@lease.key, @tokens.key], values: [token, next_token, @expiry]) == 1
      end
      private :release_script

      def non_blocking_acquire(token = nil)
        token ||= generate_token
        return acquire_script(token)
      end
      private :non_blocking_acquire

      def blocking_acquire
        timeout = @timeout == Float::INFINITY ? 0 : @timeout
        return @tokens.pop(timeout: timeout)
      end
      private :blocking_acquire

      def generate_token
        return SecureRandom.uuid
      end
      private :generate_token

      # :nocov:
      def inspectable_attributes
        super.merge(expiry: @expiry, blocking: blocking?)
      end
      # :nocov:
    end
  end
end
