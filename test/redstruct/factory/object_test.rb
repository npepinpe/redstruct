# frozen_string_literal: true
require 'test_helper'

module Redstruct
  class Factory
    class ObjectTest < Redstruct::Test
      def test_initialize
        factory = create_factory
        object = Redstruct::Factory::Object.new(factory: factory)
        assert_equal factory, object.factory, 'should have the given factory as the object factory'
      end

      def test_connection
        factory = create_factory
        object = Redstruct::Factory::Object.new(factory: factory)
        assert_equal factory.connection, object.connection, 'should delegate #connection to the factory connection'
      end
    end
  end
end
