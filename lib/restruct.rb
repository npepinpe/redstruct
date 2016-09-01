# Dependencies
require 'redis'
require 'connection_pool'

# Utility
require 'restruct/version'
require 'restruct/utils/inspectable'
require 'restruct/utils/scriptable'
require 'restruct/utils/coercion'

# Core
require 'restruct/connection'
require 'restruct/configuration'
require 'restruct/error'
require 'restruct/types/base'

# Factory
require 'restruct/factory/creation'
require 'restruct/factory/deserialization'
require 'restruct/factory'

# Base data types
require 'restruct/types/struct'
require 'restruct/types/string'
require 'restruct/types/counter'
require 'restruct/types/hash'
require 'restruct/types/list'
require 'restruct/types/script'
require 'restruct/types/set'
require 'restruct/types/sorted_set'

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
      name = Restruct if name.nil?
      self[name] = factory unless name.nil?

      return factory
    end
  end
end
