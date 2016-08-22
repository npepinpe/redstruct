require 'securerandom'

module Restruct
  module Types
    # Implementation of a simple binary lock (locked/not locked), with option to block and wait for the lock.
    # Uses two redis structures: a string for the lease, and a list for blocking operations.
    # @see #acquire
    # @see #release
    # @see #locked
    # @attr_reader [String, nil] token The current token or nil
    # @attr_reader [Fixnum] expiry The expiry of the underlying redis structures in seconds
    # @attr_reader [Fixnum, nil] timeout The timeout to wait when attempting to acquire the lock, in seconds
    class Lock < Restruct::Types::Base
      include Restruct::Utils::Scriptable, Restruct::Utils::Coercion

      # The default expiry on the underlying redis keys, in seconds
      DEFAULT_EXPIRY = 10

      # The default timeout when blocking, in seconds; a nil value means it is non-blocking
      DEFAULT_TIMEOUT = nil

      attr_reader :token, :expiry, :timeout

      # @param [Integer] expiry In seconds; to prevent infinite locking, each mutex is released after a certain expiry time
      # @param [Integer] timeout In seconds; if > 0, will block for this amount of time when trying to obtain the lock
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

      # Executes the given block if the lock can be acquired
      # @yield Block to be executed if the lock is acquired
      def locked
        yield if acquire
      ensure
        release
      end

      # Whether or not the lock will block when attempting to acquire it
      # @return [Boolean]
      def blocking?
        return @timeout > 0
      end

      # Attempts to acquire the lock. First attempts to grab the lease (a redis string).
      # If the current token is already the lease token, the lock is considered acquired.
      # If there is no current lease, then sets it to the current token.
      # If there is a current lease that is not the current token, then:
      #   1) If this not a blocking lock (see Lock#blocking?), return false
      #   2) If this is a blocking lock, block and wait for the next token to be pushed on the tokens list
      #   3) If a token was pushed, set it as our token and refresh the expiry
      # @return [Boolean] True if acquired, false otherwise
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

      # Releases the lock only if the current token is the value of the lease.
      # If the lock is a blocking lock (see Lock#blocking?), push the next token on the tokens list.
      # @return [Boolean] True if released, false otherwise
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
      # @keys [String] The lease key specifying who owns the mutex at the moment
      # @argv [String] The current token; if it is the lease value, then we can release the lock
      # @argv [Fixnum] The expiry time for lease keys in seconds
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

      # The release script compares the given token (ARGV[1]) with the lease value (KEYS[1]); if they are the same,
      # then a new token (ARGV[2]) is set as the lease, and pushed on the tokens (KEYS[2]) list
      # for the next acquire request.
      # @keys [String] The lease key specifying who owns the mutex at the moment
      # @keys [String] The tokens list key, where the next token will be pushed if we released the lock
      # @argv [String] The current token; if it is the lease value, then we can release the lock
      # @argv [String] The next token to push on the tokens list iff the lock was released
      # @argv [Fixnum] The expiry time for lease/tokens keys in seconds
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

      # :stopdoc:
      # :nocov:
      def inspectable_attributes
        super.merge(expiry: @expiry, blocking: blocking?)
      end
      # :nocov:
      # :startdoc:
    end
  end
end
