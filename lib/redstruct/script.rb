# frozen_string_literal: true

require 'digest'
require 'redis'
require 'redstruct/connection_proxy'
require 'redstruct/utils/inspectable'

module Redstruct
  # Utility class to interact with Lua scripts on Redis.
  # It is recommended you flush your script cache on the redis server every once in a while to remove scripts that
  # are not used anymore.
  class Script
    # Redis returns an error starting with NOSCRIPT when we try to evaluate am unknown script using its sha1.
    ERROR_MESSAGE_PREFIX = 'NOSCRIPT'

    # @return [String] the Lua script to evaluate
    attr_reader :script

    # @return [Redstruct::ConnectionProxy] the connection used for script commands
    attr_reader :connection

    # @param [String] script the lua source code for the script
    # @param [Redstruct::ConnectionProxy] connection connection to use for script commands
    # @param [String] sha1 the sha1 representation of the script; optional
    def initialize(script:, connection:, sha1: nil)
      self.script = script
      @connection = connection
      @sha1 = sha1 unless sha1.nil?

      raise ArgumentError, 'requires a connection proxy' unless @connection.is_a?(Redstruct::ConnectionProxy)
    end

    # Duplicates and freezes the given script, and reinitializes the sha1 (which later gets lazily computed)
    # @param [String] script the lua source code
    def script=(script)
      script = script&.strip
      raise ArgumentError, 'No source script given' if script.empty?

      @sha1 = nil
      @script = script.dup.freeze
    end

    # Returns the sha1 representation of the source code at `script`
    # When running a lua script, redis will compile it once and cache the bytecode, using the sha1 of the source code
    # as the cache key.
    # @return [String] sha1 representation of `script`
    def sha1
      return @sha1 ||= begin
        Digest::SHA1.hexdigest(@script)
      end
    end

    # Checks if the script was already loaded for the given redis db using #sha1
    # @return [Boolean] true if the script was already loaded, false otherwise
    def exists?
      return @connection.script(:exists, self.sha1)
    end

    # Loads the given script to redis (i.e. sends the source, which gets compiled and saved) and saves the returned sha1
    # @return [String] the new sha1
    def load
      @sha1 = @connection.script(:load, @script)
      return @sha1
    end

    # Evaluates the script using the given keys and argv arrays, and returns the unparsed result. Caller is in charge
    # of interpreting the result.
    # NOTE: To minimize the number of redis commands, this always first assumes that the script was already loaded using
    # its sha1 representation, and tells redis to execute the script cached by `sha1`. If it receives as error that the
    # script does not exist, only then will it send the source to be executed. So in the worst case you get 2 redis
    # commands, but in the average case you get 1, and it's much faster as redis does not have to reparse the script,
    # and we don't need to send the lua source every time.
    # @param [Array<String>] keys the KEYS array as described in the Redis doc for eval
    # @param [Array<String>] argv the ARGV array as described in the Redis doc for eval
    # @return [nil, Boolean, String, Numeric] returns whatever redis returns
    def eval(keys: [], argv: [])
      keys = [keys] unless keys.is_a?(Array)
      argv = [argv] unless argv.is_a?(Array)
      @connection.evalsha(self.sha1, keys, argv)
    rescue Redis::CommandError => err
      raise unless err.message.start_with?(ERROR_MESSAGE_PREFIX)
      @connection.eval(@script, keys, argv)
    end

    # # @!visibility private
    def inspectable_attributes # :nodoc:
      return super.merge(sha1: self.sha1, script: @script.slice(0, 20))
    end
  end
end
