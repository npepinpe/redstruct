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
    include Redstruct::Utils::Inspectable, Redstruct::Utils::Iterable

    # @return [Redstruct::ConnectionProxy] connection proxy used to execute commands
    attr_reader :connection

    # @param [Redstruct::ConnectionProxy] connection connection to use for all objects built by the factory
    # @param [String] namespace optional; all objects built from the factory will have their keys prefixed with this
    # @return [Redstruct::Factory]
    def initialize(connection: nil, namespace: '')
      namespace ||= Redstruct.config.default_namespace
      connection ||= Redstruct::ConnectionProxy.new(Redstruct.config.default_connection)

      @connection = connection
      @namespace = namespace
      @script_cache = {}.tap { |hash| hash.extend(MonitorMixin) }
    end

    # Returns a namespaced version of the key (unless already namespaced)
    # @param [String] key the key to isolate/namespace
    # @return [String] namespaced version of the key (or the key itself if already namespaced)
    def isolate(key)
      return @namespace.nil? || key.start_with?(@namespace) ? key : "#{@namespace}:#{key}"
    end

    # Use redis-rb scan_each method to iterate over particular keys
    # @return [Enumerator] base enumerator to iterate of the namespaced keys
    def to_enum(match:, count:)
      return @connection.scan_each(match: isolate(match), count: count)
    end

    # Deletes all keys created by the factory. By defaults will iterate at most of 500 million keys
    # @param [Hash] options accepts the options as given in each
    # @see Redstruct::Factory#each
    def delete(options = {})
      return each({ match: '*', count: 500, max: 1_000_000 }.merge(options)) do |keys|
        @connection.del(*keys)
      end
    end

    # @!group Factory methods

    # Returns or creates the script described by ID and source.
    # @param [String] id the ID of the script
    # @param [String] source the lua source code
    # @return [Redstruct::Script]
    def scripts(id, source)
      return @script_cache.synchronize do
        script = @script_cache[id]
        script || @script_cache.set(id, Redstruct::Script.new(script: source, factory: self))
      end
    end

    # Returns a factory with an isolated namespace.
    # @example Given a factory `f` with namespace fact:first
    #   f.factory('second') # => Redstruct::Factory: namespace: <"fact:first:second">, script_cache: <[]>
    # @return [Factory] namespaced factory
    def factory(namespace)
      return self.class.new(connection: @connection, namespace: isolate(namespace))
    end

    # Factory methods for Factory::Object subclasses
    %w(Counter Hash LexSortedSet List Lock Queue Set SortedSet String Struct).each do |type|
      method = type.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase

      next if defined?(snake_case_type) # do not redefine if overloaded
      class_eval <<~METHOD, __FILE__, __LINE__ + 1
        def #{method}(key, **options)
          isolated = isolate(key)
          return Redstruct::#{type}.new(key: isolated, factory: self, **options)
        end
      METHOD
    end

    # @!endgroup

    # # @!visibility private
    def inspectable_attributes
      return { namespace: @namespace, script_cache: @script_cache.keys }
    end
  end
end
