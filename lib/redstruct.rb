# Utility
require 'redstruct/version'

# Core
require 'redstruct/configuration'
require 'redstruct/factory'
require 'redstruct/types/all'

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
