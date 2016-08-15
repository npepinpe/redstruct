require 'securerandom'

module Restruct
  module Types
    class Lock < Restruct::Types::Base
      include Restruct::Utils::Scriptable

      # SCRIPTS

      # SCRIPTS

      DEFAULT_EXPIRY = 10 # seconds
      DEFAULT_TIMEOUT = nil # milliseconds; nil means do not block

      # @param [String] Name used to identify the owner of the mutex, should be unique in your system (e.g. UUIDs)
      # @param [Integer] In seconds; to prevent infinite locking, each mutex is released after a certain expiry time
      # @param [Integer] In milliseconds; if > 0, will block for this amount of time when trying to obtain the lock
      def initialize(name: nil, expiry: DEFAULT_EXPIRY, timeout: DEFAULT_TIMEOUT, **options)
        super(**options)

        @lease = @factory.string('lease')
        @name = name || generate_name
        @expiry = expiry
        @timeout = timeout.to_i
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
        if blocking?
          blocking_acquire
        else
          non_blocking_acquire
        end
      end

      def release
        if blocking?
          blocking_release
        else
          non_blocking_release
        end
      end

      def non_blocking_acquire
        owner = self.pipelined do
          @lease.set(@name, nx: true, expiry: @expiry)
          @lease.get
        end

        return owner == @name
      end
      private :non_blocking_acquire

      def non_blocking_release
        return @lease.delete_if_equals(@name)
      end
      private :non_blocking_release

      def blocking_acquire
        # grab lease
        # if grabbed, return true
        # if not grabbed, block until the lease is available on the list.
        # but what if whoever grabbed it crashed? then no one will push on the list...
      end
      private :blocking_acquire

      def blocking_release
      end
      private :blocking_release

      def generate_name
        return SecureRandom.uuid
      end
      private :generate_name

      # :nocov:
      def inspectable_attributes
        super.merge(name: @name, expiry: @expiry, blocking: blocking?)
      end
      # :nocov:
    end
  end
end
