# frozen_string_literal: true
require 'test_helper'

module Redstruct
  module Utils
    class ScoredValueTest < Redstruct::Test
      def test_initialize
        sv = Redstruct::Utils::ScoredValue.new(value: 'hello', score: 2)
        assert_equal 'hello', sv.value, 'should have saved the correct value'
        assert_equal 2.0, sv.score, 'should have saved the correct scored'
      end

      def test_delegation
        sv = Redstruct::Utils::ScoredValue.new(value: 'hi', score: 3)
        assert_equal 'hi', sv, 'should delegate equality'

        madeup = "hello #{sv}"
        assert_equal 'hello hi', madeup, 'should correctly behave like the string hi in most instances'
      end

      def test_comparison
        a = Redstruct::Utils::ScoredValue.new(value: 1, score: 2)
        b = Redstruct::Utils::ScoredValue.new(value: 1, score: 3)
        assert_equal(-1.0, a <=> b, 'a should be smaller than b (2 < 3)')
      end
    end
  end
end
