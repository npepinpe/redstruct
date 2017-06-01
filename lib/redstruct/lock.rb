# frozen_string_literal: true

require 'securerandom'
require 'redstruct/factory/object'
require 'redstruct/utils/scriptable'
require 'redstruct/utils/coercion'
require 'redstruct/utils/atomic_counter'

module Redstruct
  # Implementation of a simple binary lock (locked/not locked), with option to block and wait for the lock.
  # Uses two redis structures: a string for the lease, and a list for blocking operations.
  class Lock < Redstruct::Factory::Object
    include Redstruct::Utils::Scriptable
    include Redstruct::Utils::Coercion

    # The default expiry on the underlying redis keys, in seconds; can be between 0 and 1 as a float for milliseconds
    DEFAULT_EXPIRY = 1

    # The default timeout when blocking, in seconds
    DEFAULT_TIMEOUT = nil

    # @return [String] the resource name (or ID of the lock)
    attr_reader :resource

    # @return [String] the current token
    attr_reader :token

    # @return [Float, Integer] the expiry of the underlying redis structure in seconds
    attr_reader :expiry

    # @return [Integer] if greater than 0, will block until timeout is reached or the lock is acquired
    attr_reader :timeout

    # @param [String] resource the name of the resource to be locked (or ID)
    # @param [Integer] expiry in seconds; to prevent infinite locking, you should pass a minimum expiry; you can pass 0 if you want to control it yourself
    # @param [Integer] timeout in seconds; if > 0, will block when trying to obtain the lock; if 0, blocks indefinitely; if nil, does not block
    def initialize(resource, expiry: DEFAULT_EXPIRY, timeout: DEFAULT_TIMEOUT, **options)
      super(**options)

      @resource = resource
      @token = nil
      @expiry = expiry
      @acquired = Redstruct::Utils::AtomicCounter.new

      @timeout = case timeout
      when nil then nil
      when Float::INFINITY then 0
      else
        timeout.to_i
      end

      factory = @factory.factory(@resource)
      @lease = factory.string('lease')
      @tokens = factory.list('tokens')
    end

    # Deletes all traces of this lock
    # @return [Boolean] true if deleted, false otherwise
    def delete
      return coerce_bool(delete_script(keys: [@lease.key, @tokens.key]))
    end

    # Executes the given block if the lock can be acquired
    # @yield Block to be executed if the lock is acquired
    def locked
      Thread.handle_interrupt(Exception => :never) do
        begin
          if acquire
            Thread.handle_interrupt(Exception => :immediate) do
              yield
            end
          end
        ensure
          release
        end
      end
    end

    # Whether or not the lock will block when attempting to acquire it
    # @return [Boolean]
    def blocking?
      return !@timeout.nil?
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

      token = non_blocking_acquire
      token = blocking_acquire if token.nil? && blocking?

      unless token.nil?
        @lease.expire(@expiry)
        @token = token
        @acquired.increment

        acquired = true
      end

      return acquired
    end

    # Releases the lock only if the current token is the value of the lease.
    # If the lock is a blocking lock (see Lock#blocking?), push the next token on the tokens list.
    # @return [Boolean] True if released, false otherwise
    def release
      return false if @token.nil?

      released = true

      if @acquired.decrement.zero?
        keys = [@lease.key, @tokens.key]
        argv = [@token, generate_token, (@expiry.to_f * 1000).floor]

        released = coerce_bool(release_script(keys: keys, argv: argv))
        @token = nil
      end

      return released
    end

    private

    def non_blocking_acquire
      keys = [@lease.key, @tokens.key]
      argv = [@token || generate_token]

      return acquire_script(keys: keys, argv: argv)
    end

    def blocking_acquire
      return @tokens.pop(timeout: @timeout)
    end

    # The acquire script attempts to set the lease (keys[1]) to the given token (argv[1]), only
    # if it wasn't already set. It then compares to check if the value of the lease is that of the token,
    # and if so refreshes the expiry (argv[2]) time of the lease.
    # @param [Array<(::String)>] keys The lease key specifying who owns the mutex at the moment
    # @param [Array<(::String, Fixnum)>] argv the current token
    # @return [::String] Returns the token if acquired, nil otherwise.
    defscript :acquire_script, <<~LUA
      local token = ARGV[1]
      local lease = redis.call('get', KEYS[1])

      if not lease then
        redis.call('set', KEYS[1], token)
      elseif token ~= lease then
        token = redis.call('lpop', KEYS[2])
        if not token or token ~= lease then
          return false
        end
      end

      return token
    LUA

    # The release script compares the given token (argv[1]) with the lease value (keys[1]); if they are the same,
    # then a new token (argv[2]) is set as the lease, and pushed on the tokens (keys[2]) list
    # for the next acquire request.
    # @param [Array<(::String, ::String)>] keys the lease key; the tokens list key
    # @param [Array<(::String, ::String, Fixnum)>] argv the current token; the next token to push; the expiry time of both keys
    # @return [Fixnum] 1 if released, 0 otherwise
    defscript :release_script, <<~LUA
      local currentToken = ARGV[1]
      local nextToken = ARGV[2]
      local expiry = tonumber(ARGV[3])

      if redis.call('get', KEYS[1]) == currentToken then
        redis.call('set', KEYS[1], nextToken)
        redis.call('lpush', KEYS[2], nextToken)

        if expiry > 0 then
          redis.call('pexpire', KEYS[1], expiry)
          redis.call('pexpire', KEYS[2], expiry)
        end

        return true
      end

      return false
    LUA

    # Atomically deletes the given KEYS
    # @param [Array<(::String)>] keys the keys to delete
    # @return [Integer] returns the number of keys deleted
    defscript :delete_script, <<~LUA
      return redis.call('del', unpack(KEYS))
    LUA

    def generate_token
      return SecureRandom.uuid
    end

    def inspectable_attributes
      super.merge(expiry: @expiry, blocking: blocking?)
    end
  end
end
