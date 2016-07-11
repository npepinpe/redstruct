# Dependencies
require 'redis'
require 'connection_pool'

# Utility
require 'restruct/version'
require 'restruct/util/inspectable'

# Core
require 'restruct/configuration'
require 'restruct/error'
require 'restruct/factory'
require 'restruct/struct'

# Structs
require 'restruct/string'
require 'restruct/counter'
require 'restruct/hash'
require 'restruct/list'
require 'restruct/lock'
require 'restruct/set'
require 'restruct/sorted_set'

module Restruct
  class << self
    def config
      return @config ||= Configuration.new
    end

    def factories
      return @factories ||= {}
    end

    def [](key)
      factory = factories[key]
      factory = make(name: key) if factory.nil?

      return factory
    end

    def []=(key, factory)
      if factory.nil?
        factories.delete(key)
      else
        factories[key] = factory
      end
    end

    def make(name: nil, pool: nil, namespace: nil)
      factory = Restruct::Factory.new(pool: pool, namespace: namespace)
      self[name] = factory unless name.nil?

      return factory
    end
  end
end
