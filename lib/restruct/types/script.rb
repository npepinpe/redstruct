require 'digest'

module Restruct
  module Types
    class Script < Restruct::Types::Base
      ERROR_MESSAGE_PREFIX = 'NOSCRIPT'.freeze

      # @return [Symbol|String] The ID of the script in the Factory script cache. Used mostly for debugging
      attr_reader :id

      # @return [String] The Lua script to evaluate
      attr_reader :script

      def initialize(id:, script:, **options)
        script = script&.strip
        raise(Restruct::Error, 'No source script given') if script.empty?

        super(**options)
        @id = id
        self.script = script
      end

      def script=(script)
        @sha1 = nil
        @script = script.dup.freeze
      end

      def sha1
        return @sha1 ||= begin
          Digest::SHA1.hexdigest(@script)
        end
      end

      def exists?
        return self.connection.script(:exists, self.sha1)
      end

      def load
        @sha1 = self.connection.script(:load, @script)
        return @sha1
      end

      def eval(keys:, argv:)
        self.connection.evalsha(self.sha1, keys: keys, argv: argv)
      rescue Redis::CommandError => err
        raise unless err.message.start_with?(ERROR_MESSAGE_PREFIX)
        self.connection.eval(@script, keys: keys, argv: argv)
      end

      # :nocov:
      def inspectable_attributes
        return super.merge(sha1: self.sha1, script: @script.slice(0, 20))
      end
      # :nocov:
    end
  end
end
