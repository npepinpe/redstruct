# Utility
require 'redstruct/version'

# Core
require 'redstruct/configuration'
require 'redstruct/factory'

# Factory and configuration methods for the Redstruct singleton
module Redstruct
  class << self
    # @return [Redstruct::Configuration] current default configuration
    def config
      return @config ||= Redstruct::Configuration.new
    end

    # @return [Hash<String, Redstruct::Factory>] list of current existing factories
    def factories
      return @factories ||= {}
    end

    # Returns the factory at key `key`
    # @param [String] key the factory ID
    # @return [Redstruct::Factory] the factory at key
    def [](key)
      return factories[key]
    end

    # Sets the factory at key `key`. Pass nil as a factory to remove it
    # @param [String] key the factory ID
    # @param [Redstruct::Factory, nil] factory the factory; if nil, removes the key
    def []=(key, factory)
      if factory.nil?
        factories.delete(key)
      else
        factories[key] = factory
      end
    end

    # Creates a factory based and, if name is not nil, caches it
    # @param [String] name the factory ID
    # @param [ConnectionPool] pool the connection pool to use for the factory
    # @param [String] namespace the namespace for the factory
    # @see Redstruct::Factory#initialize
    # @return [Redstruct::Factory]
    def make(name: nil, pool: nil, namespace: nil)
      factory = Redstruct::Factory.new(pool: pool, namespace: namespace)
      self[name] = factory unless name.nil?

      return factory
    end
  end
end
