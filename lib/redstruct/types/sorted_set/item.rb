# frozen_string_literal: true
require 'delegate'

module Redstruct
  module Types
    class SortedSet
      # Small value object to pair a value with its score.
      # @see Redstruct::Types::SortedSet
      class Item < SimpleDelegator
        DEFAULT_SCORE = 1.0

        # @return [String] the value of the item
        attr_reader :value

        # @return [Float] the score of the item
        attr_reader :score

        # @param [#to_s] value the value of the item
        # @param [#to_f] score the score of the item
        def initialize(value:, score: DEFAULT_SCORE)
          @value = value.to_s
          @score = score.to_f
          super(@value)
        end

        def <=>(other)
          return @score <=> other.score
        end
      end
    end
  end
end
