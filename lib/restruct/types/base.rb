module Restruct
  module Types
    # Base class for all objects a factory can produce
    class Base
      include Restruct::Utils::Inspectable
      extend Forwardable

      def_delegators :@factory, :connection, :connection

      def initialize(factory:)
        @factory = factory
      end

      def pipelined
        self.connection.pool.with do |c|
          begin
            Thread.current[:__restruct_connection] = c
            yield
          ensure
            Thread.current[:__restruct_connection] = nil
          end
        end
      end

      # :nocov:
      def inspectable_attributes
        { factory: @factory }
      end
      # :nocov:
    end
  end
end
