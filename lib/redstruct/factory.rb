# frozen_string_literal: true

require 'redstruct/error'
require 'redstruct/connection_proxy'
require 'redstruct/utils/inspectable'
require 'redstruct/utils/iterable'

# Default objects; the rest you have to require
require 'redstruct/factory/object'
require 'redstruct/struct'
require 'redstruct/script'

module Redstruct
  # Main interface of the gem; this class should be used to build all Redstruct
  # objects, even when deserializing them.
  class Factory
    include Redstruct::Utils::Inspectable
    include Redstruct::Utils::Iterable

    # @return [String] namespace used to prefix the keys of all objects created by this factory
    attr_reader :namespace

    # @return [Redstruct::ConnectionProxy] connection proxy used to execute commands
    attr_reader :connection

    # @param [Redstruct::ConnectionProxy] connection connection to use for all objects built by the factory
    # @param [String] namespace optional; all objects built from the factory will have their keys prefixed with this
    # @raise [ArgumentError] raised if connection is not nil, and not a Redstruct::ConnectionProxy
    # @return [Redstruct::Factory]
    def initialize(connection: nil, namespace: nil)
      namespace ||= Redstruct.config.default_namespace
      connection ||= Redstruct::ConnectionProxy.new(Redstruct.config.default_connection)

      raise ArgumentError, 'connection should be a Redstruct::ConnectionProxy' unless connection.is_a?(Redstruct::ConnectionProxy)

      @connection = connection
      @namespace = namespace.to_s
    end

    # Returns a namespaced version of the key (unless already namespaced)
    # @param [String] key the key to namespace
    # @return [String] namespaced version of the key (or the key itself if already namespaced)
    def prefix(key)
      prefixed = key
      prefixed = "#{@namespace}:#{key}" unless @namespace.empty? || key.start_with?("#{@namespace}:")

      return prefixed
    end

    # Use redis-rb scan_each method to iterate over particular keys
    # @
    # @return [Enumerator] base enumerator to iterate of the namespaced keys
    def to_enum(match: '*', count: 10)
      return @connection.scan_each(match: prefix(match), count: count)
    end

    # Deletes all keys created by the factory. By defaults will iterate at most of 500 million keys
    # @param [Hash] options accepts the options as given in each
    # @see Redstruct::Factory#each
    def delete(options = {})
      return each({ match: '*', count: 500, max_iterations: 1_000_000, batch_size: 500 }.merge(options)) do |keys|
        @connection.del(*keys)
      end
    end

    # @!group Factory methods

    # Returns a factory for a sub namespace.
    # @example Given a factory `f` with namespace fact:first
    #   f.factory('second') # => Redstruct::Factory: namespace: <"fact:first:second">>
    # @return [Factory] namespaced factory
    def factory(namespace)
      return self.class.new(connection: @connection, namespace: prefix(namespace))
    end

    # Creates using this factory's connection
    # @see Redstruct::Script#new
    # @return [Redstruct::Script] script sharing the factory connection
    def script(script, **options)
      return Redstruct::Script.new(script: script, connection: @connection, **options)
    end

    # Creates a lock for the given resource within this factory
    # @see Redstruct::Lock#new
    # @return [Redstruct::Lock] lock for the given resource within this factory
    def lock(resource, **options)
      return Redstruct::Lock.new(resource, factory: self, **options)
    end

    # Creates a time series for the given ID within this factory
    # @see Redstruct::TimeSeries#new
    # @return [Redstruct::TimeSeries] time series for the given ID within this factory
    def time_series(id, **options)
      return Redstruct::TimeSeries.new(id, factory: self, **options)
    end

    # Factory methods for struct classes
    {
      Counter: :counter,
      Hash: :hashmap,
      List: :list,
      Set: :set,
      SortedSet: :sorted_set,
      String: :string,
      Struct: :struct
    }.each do |class_name, method_name|
      unless defined?(class_name)
        Redstruct.logger.warn("cannot define factory method #{method_name} for non-existing class Redstruct::#{class_name}")
        next
      end

      if method_defined?(method_name)
        Redstruct.logger.warn("trying to redefine Redstruct::Factory##{method_name}; already defined?")
        next
      end

      class_eval <<~METHOD, __FILE__, __LINE__ + 1
        def #{method_name}(key, **options)
          return Redstruct::#{class_name}.new(key: prefix(key), factory: self, **options)
        end
      METHOD
    end

    # @!endgroup

    private

    def inspectable_attributes
      return { namespace: @namespace, connection: @connection }
    end
  end
end
