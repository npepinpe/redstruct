# frozen_string_literal: true
require 'test_helper'
require 'flexmock/minitest'

module Redstruct
  module Utils
    class InspectableTest < Redstruct::Test
      def test_inspect
        child = flexmock('test')
        child.should_receive(:inspect).and_return('child').once
        other = 'val'

        object = self.class::Test.new(child: child, other: other)
        assert_equal %(Redstruct::Utils::InspectableTest::Test: child: <child>, other: <"val">), object.inspect, 'should generate the correct inspect string, calling inspect on all values'
      end

      class Test
        include Redstruct::Utils::Inspectable

        def initialize(attrs)
          @attrs = attrs
        end

        def inspectable_attributes
          return @attrs
        end
      end
    end
  end
end
