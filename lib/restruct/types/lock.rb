require 'securerandom'

module Restruct
  module Types
    class Lock < Restruct::Types::Base
      include Restruct::Utils::Scriptable, Restruct::Utils::Coercion

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
          # since it was popped from a list, need to update the expiry time of the lease, it could be old
          @lease.expire(@expiry) if blocking?
          acquired = true
        end

        return acquired
      end

      def release
        return false if @token.nil?

        next_token = SecureRandom.uuid
        return coerce_bool(release_script(keys: [@lease.key, @tokens.key], values: [@token, next_token, @expiry]))
      end

      def non_blocking_acquire(token = nil)
        token ||= generate_token
        return acquire_script(keys: @lease.key, values: [token, @expiry])
      end
      private :non_blocking_acquire

      def blocking_acquire
        timeout = @timeout == Float::INFINITY ? 0 : @timeout
        return @tokens.pop(timeout: timeout)
      end
      private :blocking_acquire

      # The acquire script attempts to set the lease (KEYS[1]) to the given token (ARGV[1]), only
      # if it wasn't already set. It then compares to check if the value of the lease is that of the token,
      # and if so refreshes the expiry (ARGV[2]) time of the lease.
      # KEYS:
      # @param [String] The lease key specifying who owns the mutex at the moment
      # ARGV:
      # @param [String] The current token; if it is the lease value, then we can release the lock
      # @param [Fixnum] The expiry time for lease keys in seconds
      # @return [String] Returns the token if acquired, nil otherwise.
      defscript :acquire_script, <<~LUA
        local token = ARGV[1]
        local expiry = tonumber(ARGV[2])

        redis.call('set', KEYS[1], token, 'NX')
        if redis.call('get', KEYS[1]) == token then
          redis.call('expire', KEYS[1], expiry)
          return token
        end

        return false
      LUA
      protected :acquire_script

      # The release script compares the given token (ARGV[1]) with the lease value (KEYS[1]); if they are the same,
      # then a new token (ARGV[2]) is set as the lease, and pushed on the tokens (KEYS[2]) list
      # for the next acquire request.
      # KEYS:
      # @param [String] The lease key specifying who owns the mutex at the moment
      # @param [String] The tokens list key, where the next token will be pushed if we released the lock
      # ARGV:
      # @param [String] The current token; if it is the lease value, then we can release the lock
      # @param [String] The next token to push on the tokens list iff the lock was released
      # @param [Fixnum] The expiry time for lease/tokens keys in seconds
      # @return [Fixnum] 1 if released, 0 otherwise
      defscript :release_script, <<~LUA
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
      protected :release_script

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
