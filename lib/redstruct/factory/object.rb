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
      # @return [Redstruct::ConnectionProxy]
      def connection
        return @factory.connection
      end

      # # @!visibility private
      def inspectable_attributes
        { factory: @factory }
      end
    end
  end
end
