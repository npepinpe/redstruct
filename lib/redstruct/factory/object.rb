# frozen_string_literal: true
require 'redstruct/utils/inspectable'

module Redstruct
  class Factory
    # Base class for all objects a factory can produce
    class Object
      include Redstruct::Utils::Inspectable

      # @param [Redstruct::Factory] factory the factory which produced the object
      def initialize(factory:)
        @factory = factory
      end

      # Convenience accessor for the factory's connection
      # @return [Redstruct::Connection]
      def connection
        return @factory.connection
      end

      # :nocov:
      def inspectable_attributes
        { factory: @factory }
      end
      # :nocov:
    end
  end
end
