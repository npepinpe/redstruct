# frozen_string_literal: true
require 'securerandom'
require 'redstruct/types/base'
require 'redstruct/utils/scriptable'
require 'redstruct/utils/coercion'

module Redstruct
  module Types
    # Implementation of a simple binary lock (locked/not locked), with option to block and wait for the lock.
    # Uses two redis structures: a string for the lease, and a list for blocking operations.
    # @see #acquire
    # @see #release
    # @see #locked
    # @attr_reader [::String, nil] token the current token or nil
    # @attr_reader [Fixnum] expiry expiry of the underlying redis structures in milliseconds
    # @attr_reader [Fixnum, nil] timeout the timeout to wait when attempting to acquire the lock, in seconds
    class Lock < Redstruct::Types::Base
      include Redstruct::Utils::Scriptable

      # The default expiry on the underlying redis keys, in milliseconds
      DEFAULT_EXPIRY = 1000

      # The default timeout when blocking, in seconds; a nil value means it is non-blocking
      DEFAULT_TIMEOUT = nil

      # @return [String] the current token
      attr_reader :token

      # @return [Float, Integer] the expiry of the underlying redis structure in seconds
      attr_reader :expiry

      # @return [Integer] if greater than 0, will block until timeout is reached or the lock is acquired
      attr_reader :timeout

      # @param [Integer] expiry in milliseconds; to prevent infinite locking, each mutex is released after a certain expiry time
      # @param [Integer] timeout in seconds; if > 0, will block for this amount of time when trying to obtain the lock
      def initialize(key:, expiry: DEFAULT_EXPIRY, timeout: DEFAULT_TIMEOUT, **options)
        super(**options)

        @key = key
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
        return @timeout.positive?
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
        return coerce_bool(release_script(keys: [@lease.key, @tokens.key], argv: [@token, next_token, @expiry]))
      end

      def non_blocking_acquire(token = nil)
        token ||= generate_token
        return acquire_script(keys: @lease.key, argv: [token, @expiry])
      end
      private :non_blocking_acquire

      def blocking_acquire
        timeout = @timeout == Float::INFINITY ? 0 : @timeout
        token = @tokens.pop(timeout: timeout)

        # Attempt to reacquire in a non blocking way to:
        # 1) assert we do own the lock (edge case)
        # 2) touch the lock expiry
        token = non_blocking_acquire(token) unless token.nil?

        return token
      end
      private :blocking_acquire

      # The acquire script attempts to set the lease (keys[1]) to the given token (argv[1]), only
      # if it wasn't already set. It then compares to check if the value of the lease is that of the token,
      # and if so refreshes the expiry (argv[2]) time of the lease.
      # @param [Array<(::String)>] keys The lease key specifying who owns the mutex at the moment
      # @param [Array<(::String, Fixnum)>] argv The current token; the expiry time in milliseconds
      # @return [::String] Returns the token if acquired, nil otherwise.
      defscript :acquire_script, <<~LUA
        local token = ARGV[1]
        local expiry = tonumber(ARGV[2])

        redis.call('set', KEYS[1], token, 'NX')
        if redis.call('get', KEYS[1]) == token then
          redis.call('pexpire', KEYS[1], expiry)
          return token
        end

        return false
      LUA

      # The release script compares the given token (argv[1]) with the lease value (keys[1]); if they are the same,
      # then a new token (argv[2]) is set as the lease, and pushed on the tokens (keys[2]) list
      # for the next acquire request.
      # @param [Array<(::String, ::String)>] keys The lease key; the tokens list key
      # @param [Array<(::String, ::String, Fixnum)>] argv The current token; the next token to push; the expiry time of both keys
      # @return [Fixnum] 1 if released, 0 otherwise
      defscript :release_script, <<~LUA
        local currentToken = ARGV[1]
        local nextToken = ARGV[2]
        local expiry = tonumber(ARGV[3])

        if redis.call('get', KEYS[1]) == currentToken then
          redis.call('set', KEYS[1], nextToken, 'PX', expiry)
          redis.call('lpush', KEYS[2], nextToken)
          redis.call('pexpire', KEYS[2], expiry)
          return true
        end

        return false
      LUA

      # @!group Serialization
      # Returns a hash representation of the object
      # @see Lock#from_h
      # @return [Hash<Symbol, Object>] hash representation of the lock
      def to_h
        return super.merge(token: @token, expiry: @expiry, timeout: @timeout)
      end

      class << self
        # Builds a lock from a hash.
        # @see Lock#to_h
        # @see Factory#create_from_h
        # @param [Hash] hash hash generated by calling Lock#to_h. Ensure beforehand that keys are symbols.
        # @return [Lock]
        def from_h(hash, factory)
          hash[:factory] = factory
          return new(**hash)
        end
      end
      # @!endgroup

      def generate_token
        return SecureRandom.uuid
      end
      private :generate_token

      # Helper method for easy inspection
      def inspectable_attributes
        super.merge(expiry: @expiry, blocking: blocking?)
      end
    end
  end
end
