require 'securerandom'

module Restruct
  module Types
    class Lock < Restruct::Types::Base
      include Restruct::Utils::Inspectable

      DEFAULT_EXPIRY = 10 # seconds
      DEFAULT_TIMEOUT = 0 # milliseconds; 0 means do not block

      # @param [String] Name used to identify the owner of the mutex, should be unique in your system (e.g. UUIDs)
      # @param [Integer] In seconds; to prevent infinite locking, each mutex is released after a certain expiry time
      # @param [Integer] In milliseconds; if > 0, will block for this amount of time when trying to obtain the lock
      def initialize(name: nil, expiry: DEFAULT_EXPIRY, timeout: DEFAULT_TIMEOUT, **options)
        super(**options)

        @state = @factory.string('state')
        @free = @factory.list('free')
        @busy = @factory.list('busy')
        @name = name || generate_owner
        @expiry = expiry
        @timeout = timeout
      end

      def acquire

      end

      def locked?
        return @state.get != @name
      end

      def with_lock
        if acquire
          begin
            yield
          ensure
            release
          end
        end
      end

      def release

        if @timeout.nil?
          self.connection.rpoplpush()
        else
          self.connection.brpoplpush()
        end
      end

      def assert_staleness!
        if @state.setnx(@name)

        end
      end
      private :assert_staleness!

      def generate_name
        return SecureRandom.uuid
      end
      private :generate_name
    end
  end
end
