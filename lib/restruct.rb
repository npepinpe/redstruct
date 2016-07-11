# Dependencies
require 'redis'
require 'connection_pool'

# Utility
require 'restruct/version'

# Core
require 'restruct/configuration'
require 'restruct/error'
require 'restruct/factory'

class Restruct
  Config = Configuration.new

  class << self
    @factories = {}

    def [](key)
      factory = @factories[key]
      factory = make(name: key, pool: Config.connection_pool) if factory.nil?

      return factory
    end

    def []=(key, factory)
      if factory.nil?
        @factories.delete(key)
      else
        @factories[key] = factory
      end
    end

    def make(name: nil, pool: nil, namespace: nil)
      pool ||= Config.connection_pool
      raise(Restruct::Error, 'Connection pool was not configured, nor passed to #create call. A connection pool is required to use a Restruct::Factory.')
      factory = Restruct::Factory.new(pool: pool, namespace: namespace)
      self[name] = factory unless name.nil?

      return factory
    end
  end
end
