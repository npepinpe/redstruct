module Redstruct
  # Main interface of the gem; this class should be used to build all Redstruct
  # objects, even when deserializing them.
  class Factory
    include Redstruct::Utils::Inspectable, Redstruct::Factory::Creation
    extend Redstruct::Factory::Deserialization

    # @return [Connection] The connection proxy to use when executing commands. Shared by all factory produced objects.
    attr_reader :connection

    # @param [Redstruct::Connection] connection connection to use for all objects built by the factory
    # @param [ConnectionPool] pool pool to use to build a connection from if no connection param given
    # @param [::String] namespace all objects build from the factory will have their keys namespaced under this one
    # @return [Factory]
    def initialize(connection: nil, pool: nil, namespace: nil)
      namespace ||= Redstruct.config.namespace

      if connection.nil?
        pool ||= Redstruct.config.connection_pool
        raise(Redstruct::Error, 'A connection pool is required to create a factory, but none was given') if pool.nil?
        connection = Redstruct::Connection.new(pool)
      end

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

    # :nocov:

    # Helper method for serialization
    def inspectable_attributes
      return { namespace: @namespace, script_cache: @script_cache.keys }
    end

    # :nocov:
  end
end
