# frozen_string_literal: true

require 'test_helper'

module Redstruct
  module Utils
    class CoercionTest < Redstruct::TestCase
      class Coerced
        include Redstruct::Utils::Coercion
      end

      def setup
        super
        @object = Coerced.new
      end

      def test_coerce_bool
        refute @object.coerce_bool(nil), 'nil should be coerced to false'
        refute @object.coerce_bool(false), 'false should be coerced to false'
        refute @object.coerce_bool(0), '0 should be coerced to false'
        refute @object.coerce_bool(0.0), '0.0 should be coerced to false'
        assert @object.coerce_bool(1), 'any non-zero number should be coerced to true'

        [[], {}, '', true, 3.0, Object.new].each do |value|
          assert @object.coerce_bool(value), 'should be coerced to true'
        end
      end

      def test_coerce_array
        assert_equal [], @object.coerce_array(nil), 'nil should be coerced to empty array'

        array = [1, 2, 3]
        assert_equal array, @object.coerce_array(array), 'array should be returned as is'

        hash = { a: 1, b: 2 }
        assert_equal hash.to_a, @object.coerce_array(hash), '#to_a should be coerced to its array representation'

        assert_equal [1], @object.coerce_array(1), 'non #to_a should be coerced to an array containing the given value'
      end
    end
  end
end
