# Dependencies
require 'redis'
require 'connection_pool'

# Utility
require 'redstruct/version'
require 'redstruct/utils/inspectable'
require 'redstruct/utils/scriptable'
require 'redstruct/utils/coercion'

# Core
require 'redstruct/connection'
require 'redstruct/configuration'
require 'redstruct/error'
require 'redstruct/types/base'

# Factory
require 'redstruct/factory/creation'
require 'redstruct/factory/deserialization'
require 'redstruct/factory'

# Base data types
require 'redstruct/types/struct'
require 'redstruct/types/string'
require 'redstruct/types/counter'
require 'redstruct/types/hash'
require 'redstruct/types/list'
require 'redstruct/types/script'
require 'redstruct/types/set'
require 'redstruct/types/sorted_set'

module Redstruct
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
      factory = Redstruct::Factory.new(pool: pool, namespace: namespace)
      name = Redstruct if name.nil?
      self[name] = factory unless name.nil?

      return factory
    end
  end
end
