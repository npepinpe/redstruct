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
      return @factories ||= {}.tap { |hash| hash.extend(MonitorMixin) }
    end
    private :factories

    # Returns the factory at key `key`
    # @param [String] name the factory ID
    # @return [Redstruct::Factory] the factory at key
    def [](name)
      return factories.synchronize { factories[name] }
    end

    # Deletes a factory from the cache.
    # @param [String] name the name of the factory
    # @param [Boolean] clear if true, attempts to delete all keys created by the factory
    def delete(name, clear: false)
      factories.synchronize do
        factory = factories[name]
        factories.delete(name)
        factory.delete if !factory.nil? && clear
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
      factories.synchronize { factories[name] = factory } unless name.nil?
      return factory
    end
  end
end
